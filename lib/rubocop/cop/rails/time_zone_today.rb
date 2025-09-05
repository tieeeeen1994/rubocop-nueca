# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      class TimeZoneToday < RuboCop::Cop::Base
        MSG = 'Do not use Time.zone.today.'
        RESTRICT_ON_SEND = [:today].freeze

        def_node_matcher :time_zone_today_usage, <<~PATTERN
          (send
            (send
              (const nil? :Time) :zone) :today)
        PATTERN

        def on_send(node)
          return unless time_zone_today_usage(node)

          add_offense(node)
        end
      end
    end
  end
end
