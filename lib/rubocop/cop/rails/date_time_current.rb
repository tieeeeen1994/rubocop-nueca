# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      class DateTimeCurrent < RuboCop::Cop::Base
        MSG = 'Use Time.current instead of DateTime.current.'
        RESTRICT_ON_SEND = [:current].freeze

        def_node_matcher :datetime_curent_usage, <<~PATTERN
          (send
            (const nil? :DateTime) :current)
        PATTERN

        def on_send(node)
          return unless datetime_curent_usage(node)

          add_offense(node)
        end
      end
    end
  end
end
