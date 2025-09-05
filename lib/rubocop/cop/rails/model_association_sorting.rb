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

        def check_association_sorting(associations)
          grouped = associations.group_by { |assoc| assoc[:method] }

          grouped.each_value do |group_associations|
            next if group_associations.size < 2

            check_group_sorting(group_associations)
          end
        end

        def check_group_sorting(group_associations)
          names = group_associations.map { |assoc| assoc[:name] }
          sorted_names = names.sort

          return if names == sorted_names

          expected_order = sorted_names.join(', ')
          message = format(MSG, expected: expected_order)

          add_offense(group_associations.first[:node], message: message)
        end
      end
    end
  end
end
