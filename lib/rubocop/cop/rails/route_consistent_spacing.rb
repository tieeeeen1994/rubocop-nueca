# frozen_string_literal: true

require_relative '../shared/route_helper'

module RuboCop
  module Cop
    module Rails
      class RouteConsistentSpacing < RuboCop::Cop::Base
        include RouteHelper

        MSG = 'Do not leave blank lines between routes of the same type at the same namespace level.'

        def on_block(node)
          process_route_block(node)
        end

        def investigate(processed_source)
          process_route_file(processed_source)
        end

        private

        def check_routes(routes)
          check_consistent_spacing(routes)
        end

        def check_consistent_spacing(routes)
          routes.each_with_index do |current_route, index|
            next_route = routes[index + 1]
            next unless next_route
            next unless same_type_and_level?(current_route, next_route)

            add_offense(next_route[:node], message: MSG) if blank_line_between?(current_route, next_route)
          end
        end

        def same_type_and_level?(current_route, next_route)
          current_route[:type] == next_route[:type] &&
            current_route[:namespace_level] == next_route[:namespace_level]
        end

        def blank_line_between?(current_route, next_route)
          current_end_line = current_route[:end_line]
          next_start_line = next_route[:line]
          lines_between = next_start_line - current_end_line - 1

          lines_between >= 1
        end
      end
    end
  end
end
