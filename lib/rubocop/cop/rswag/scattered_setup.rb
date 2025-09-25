# frozen_string_literal: true

module RuboCop
  module Cop
    module RSwag
      class ScatteredSetup < RuboCop::Cop::Base
        MSG = 'Do not define multiple hooks of the same type in the same response group.'

        def on_block(node)
          return unless rswag_test?(node)

          hooks = analyzable_hooks(node)
          hooks.group_by { |hook| hook.send_node.method_name }.each_value do |group|
            next if group.size <= 1

            group[1..].each { |hook| add_offense(hook) }
          end
        end

        private

        def rswag_test?(_node)
          processed_source.file_path&.include?('spec/requests/api')
        end

        def analyzable_hooks(node)
          hook_methods = [:before, :after, :around]
          node.body&.each_child_node(:block)&.select do |blk|
            hook_methods.include?(blk.send_node&.method_name)
          end || []
        end
      end
    end
  end
end
