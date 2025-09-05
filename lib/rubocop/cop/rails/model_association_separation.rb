# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      class ModelAssociationSeparation < RuboCop::Cop::Base
        MSG = 'Separate different association types with a blank line.'
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

          check_association_separation(associations)
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

        def check_association_separation(associations)
          associations.each_with_index do |current, index|
            next_assoc = associations[index + 1]
            break unless next_assoc
            next if same_association_type?(current, next_assoc)
            next if properly_separated?(current, next_assoc)

            add_offense(next_assoc[:node], message: MSG)
          end
        end

        def same_association_type?(current, next_assoc)
          current[:method] == next_assoc[:method]
        end

        def properly_separated?(current, next_assoc)
          current_end_line = current[:end_line]
          next_start_line = next_assoc[:start_line]
          lines_between = next_start_line - current_end_line - 1

          return true if lines_between >= 2

          if lines_between == 1
            between_line = current_end_line
            line_content = processed_source.lines[between_line].strip
            return line_content.empty?
          end

          false
        end
      end
    end
  end
end
