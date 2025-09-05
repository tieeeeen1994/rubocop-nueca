# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      class ModelAssociationScattering < RuboCop::Cop::Base
        MSG = 'Group all associations together without non-association code scattered between them.'
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

          check_association_scattering(associations, node)
        end

        private

        def model_class?(node)
          node_parent = node.parent_class
          return false unless node_parent

          parent_class = node_parent
          parent_name = parent_class.const_name
          ['ApplicationRecord', 'ActiveRecord::Base'].include?(parent_name)
        end

        def find_associations(class_node)
          associations = []

          class_node.body&.each_child_node do |child|
            next unless child.type == :send
            next unless association_method?(child)

            associations << child
          end

          associations.sort_by { |assoc| assoc.loc.line }
        end

        def association_method?(node)
          return false unless node.receiver.nil?

          ASSOCIATION_METHODS.include?(node.method_name)
        end

        def check_association_scattering(associations, class_node)
          scattered_associations = find_scattered_associations(associations, class_node)

          scattered_associations.each do |association|
            add_offense(association, message: MSG)
          end
        end

        def find_scattered_associations(associations, class_node)
          return [] if associations.size <= 1

          scattered = []
          body_node = class_node.body

          associations.each_with_index do |assoc, index|
            next if index.zero?

            current_line = assoc.loc.line
            prev_assoc = associations[index - 1]
            prev_line = prev_assoc.loc.line

            if non_association_between?(body_node, prev_line, current_line) && !scattered.include?(assoc) # rubocop:disable Rails/NegateInclude
              scattered << assoc
            end
          end

          scattered
        end

        def non_association_between?(body_node, start_line, end_line)
          body_node&.each_child_node do |child|
            child_line = child.loc.line
            return true if child_line > start_line && child_line < end_line && !association_node?(child)
          end
          false
        end

        def association_node?(node)
          node.type == :send && ASSOCIATION_METHODS.include?(node.method_name)
        end
      end
    end
  end
end
