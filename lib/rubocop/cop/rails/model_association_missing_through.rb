# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      class ModelAssociationMissingThrough < RuboCop::Cop::Base
        MSG = 'Association %<association>s references through %<through>s, ' \
              'but %<through>s is not defined in this model.'
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

          check_missing_through_associations(associations)
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

            associations << {
              node: child,
              method: child.method_name,
              name: association_name(child),
              through: association_through(child)
            }
          end

          associations
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

        def check_missing_through_associations(associations)
          defined_associations = associations.to_set { |assoc| assoc[:name] }

          associations.each do |assoc|
            next unless assoc[:through]

            next if defined_associations.include?(assoc[:through])

            message = format(MSG,
                             association: assoc[:name],
                             through: assoc[:through])
            add_offense(assoc[:node], message: message)
          end
        end
      end
    end
  end
end
