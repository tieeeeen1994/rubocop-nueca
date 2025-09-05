# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      class ModelAssociationGrouping < RuboCop::Cop::Base
        MSG = 'Group associations of the same type together.'
        ASSOCIATION_METHODS = [
          :belongs_to,
          :has_one,
          :has_many,
          :has_and_belongs_to_many
        ].freeze

        def on_class(node)
          return unless model_class?(node)

          associations = find_associations(node)
          return if associations.empty?

          check_association_grouping(associations)
        end

        private

        def model_class?(node)
          node_parent = node.parent_class
          return false unless node_parent

          parent_class = node_parent
          parent_class_name = case parent_class.type
                              when :const
                                parent_class.const_name
                              else
                                parent_class.source
                              end

          parent_class_name&.include?('ApplicationRecord') ||
            parent_class_name&.include?('ActiveRecord::Base')
        end

        def find_associations(class_node)
          associations = []

          body = class_node.body
          body&.each_child_node do |child|
            child_type = child.type
            next unless child_type == :send

            method_name = child.method_name
            associations << child if ASSOCIATION_METHODS.include?(method_name)
          end

          associations
        end

        def check_association_grouping(associations)
          grouped_associations = associations.group_by(&:method_name)

          grouped_associations.each_value do |same_type_associations|
            next if same_type_associations.length <= 1

            check_same_type_grouping(same_type_associations, associations)
          end
        end

        def check_same_type_grouping(same_type_associations, all_associations)
          groups = find_contiguous_groups(same_type_associations, all_associations)

          return unless groups.length > 1

          groups[1..].each do |group|
            add_offense(group.first, message: MSG)
          end
        end

        def find_contiguous_groups(same_type_associations, all_associations)
          return [] if same_type_associations.empty?

          target_method = same_type_associations.first.method_name
          sorted_associations = all_associations.sort_by { |assoc| assoc.loc.line }

          build_contiguous_groups(sorted_associations, target_method)
        end

        def build_contiguous_groups(sorted_associations, target_method)
          groups = []
          current_group = []

          (sorted_associations + [nil]).each do |association|
            if association && matches_target_method?(association, target_method)
              current_group << association
            else
              finalize_group(groups, current_group)
            end
          end

          groups
        end

        def finalize_group(groups, current_group)
          return unless current_group.any?

          groups << current_group.dup
          current_group.clear
        end

        def matches_target_method?(association, target_method)
          association.method_name == target_method
        end
      end
    end
  end
end
