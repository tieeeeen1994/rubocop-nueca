# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      class AutoTimeDefinition < RuboCop::Cop::Base
        MSG = 'Use autotime(...) helper instead of using Date, DateTime or Time.'
        RESTRICT_ON_SEND = [:new, :today, :now].freeze

        def_node_matcher :datetime_usage, <<~PATTERN
          (send
            (const nil? {:DateTime | :Time | :Date}) ...)
        PATTERN

        def on_send(node)
          return if node.source_range.source_buffer.name.exclude?('_spec.rb')
          return unless datetime_usage(node)

          add_offense(node)
        end
      end
    end
  end
end
