# frozen_string_literal: true

# :nocov:
module CustomCop
  module Capybara
    class BrowserDriver < ::RuboCop::Cop::Base
      MSG = 'Use default driver instead of :browser.'

      def_node_matcher :browser_usage, <<~PATTERN
        (send _ _ _ (sym :browser) ...)
      PATTERN

      def on_send(node)
        return unless node.source_range.source_buffer.name.include?('_spec.rb')
        return unless browser_usage(node)

        add_offense(node)
      end
    end
  end
end
# :nocov:
