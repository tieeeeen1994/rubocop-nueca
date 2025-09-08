# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      class ModelAssociationSorting < RuboCop::Cop::Base
        MSG = 'Sort associations of the same type alphabetically. Expected order: %<expected>s.'
        ASSOCIATION_METHODS = [
          :belongs_to,
          :has_one,
          :has_many,
          :has_and_belongs_to_many
        ].freeze

        def on_class(node)
          return unless model_class?(node)

          associations = find_associations(node)
          return if associations.size < 2

          check_association_sorting(associations)
        end

        private

        def model_class?(node)
          parent_class = node.parent_class
          return false unless parent_class

          parent_name = parent_class.const_name
          ['ApplicationRecord', 'ActiveRecord::Base'].include?(parent_name)
        end

        def find_associations(class_node)
          associations = []

          class_node.body&.each_child_node do |child|
            next unless child.type == :send
            next unless association_method?(child)

            source_range = child.source_range
            associations << {
              node: child,
              method: child.method_name,
              name: association_name(child),
              through: association_through(child),
              start_line: source_range.line,
              end_line: source_range.last_line
            }
          end

          associations.sort_by { |assoc| assoc[:start_line] }
        end

        def association_method?(node)
          return false unless node.receiver.nil?

          ASSOCIATION_METHODS.include?(node.method_name)
        end

        def association_name(node)
          first_arg = node.arguments.first
          return nil unless first_arg&.sym_type?

          first_arg.value.to_s
        end

        def association_through(node)
          options_hash = find_options_hash(node)
          return nil unless options_hash

          through_pair = options_hash.pairs.find do |pair|
            pair.key.sym_type? && pair.key.value == :through
          end

          return nil unless through_pair&.value&.sym_type?

          through_pair.value.value.to_s
        end

        def find_options_hash(node)
          node.arguments.find(&:hash_type?)
        end

        def check_association_sorting(associations)
          grouped = associations.group_by { |assoc| assoc[:method] }

          grouped.each_value do |group_associations|
            next if group_associations.size < 2

            check_group_sorting(group_associations)
          end
        end

        def check_group_sorting(group_associations)
          # Separate associations with and without through
          through_associations = group_associations.select { |assoc| assoc[:through] }
          regular_associations = group_associations.reject { |assoc| assoc[:through] }

          # Sort regular associations alphabetically
          regular_sorted = regular_associations.sort_by { |assoc| assoc[:name] }

          # Build expected order respecting through dependencies
          expected_order = build_expected_order(regular_sorted, through_associations)
          actual_order = group_associations.map { |assoc| assoc[:name] }

          return if actual_order == expected_order

          expected_order_str = expected_order.join(', ')
          message = format(MSG, expected: expected_order_str)

          add_offense(group_associations.first[:node], message: message)
        end

        def build_expected_order(regular_associations, through_associations)
          expected = []

          # Add regular associations first, sorted alphabetically
          regular_associations.each do |assoc|
            expected << assoc[:name]

            # Add any through associations that depend on this one
            dependent_through = through_associations.select { |ta| ta[:through] == assoc[:name] }
            dependent_through.sort_by { |ta| ta[:name] }.each do |ta|
              expected << ta[:name]
            end
          end

          # Add any through associations that don't have dependencies in this group
          orphaned_through = through_associations.reject do |ta|
            regular_associations.any? { |ra| ra[:name] == ta[:through] }
          end
          orphaned_through.sort_by { |ta| ta[:name] }.each do |ta|
            expected << ta[:name]
          end

          expected
        end
      end
    end
  end
end
