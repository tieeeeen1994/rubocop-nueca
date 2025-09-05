# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      class DateTimeConversion < RuboCop::Cop::Base
        MSG = 'Use in_time_zone(...) instead of using to_datetime.'
        RESTRICT_ON_SEND = [:to_datetime].freeze

        def on_send(node)
          add_offense(node)
        end

        def on_csend(node)
          return unless node.method_name == :to_datetime

          add_offense(node)
        end
      end
    end
  end
end
