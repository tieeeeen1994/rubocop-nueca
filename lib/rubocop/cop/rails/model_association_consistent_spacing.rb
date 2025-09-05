# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      class ModelAssociationConsistentSpacing < RuboCop::Cop::Base
        MSG = 'Do not leave blank lines between associations of the same type.'
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

          check_consistent_spacing(associations)
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
            next unless child.type == :send

            method_name = child.method_name
            associations << child if ASSOCIATION_METHODS.include?(method_name)
          end

          associations
        end

        def check_consistent_spacing(associations)
          associations.each_cons(2) do |prev_assoc, curr_assoc|
            next unless prev_assoc.method_name == curr_assoc.method_name

            prev_end_line = prev_assoc.loc.last_line
            curr_start_line = curr_assoc.loc.line

            next unless curr_start_line - prev_end_line > 1

            add_offense(curr_assoc, message: MSG)
          end
        end
      end
    end
  end
end
