# frozen_string_literal: true

require_relative '../shared/route_helper'

module RuboCop
  module Cop
    module Rails
      class RouteSeparation < RuboCop::Cop::Base
        include RouteHelper

        MSG = 'Separate different route types with a blank line.'

        def on_block(node)
          process_route_block(node)
        end

        def investigate(processed_source)
          process_route_file(processed_source)
        end

        private

        def check_routes(routes)
          check_route_separation(routes)
        end

        def check_route_separation(routes)
          routes_by_context = routes.group_by do |route|
            [route[:namespace_level], route[:namespace_path]]
          end

          routes_by_context.each_value do |context_routes|
            next if context_routes.size < 2

            check_separation_within_context(context_routes)
          end
        end

        def check_separation_within_context(routes)
          routes.each_with_index do |current_route, index|
            next_route = routes[index + 1]
            break unless next_route
            next if same_route_type?(current_route, next_route)
            next if properly_separated?(current_route, next_route)

            add_offense(next_route[:node], message: MSG)
          end
        end

        def same_route_type?(current_route, next_route)
          current_route[:type] == next_route[:type]
        end

        def properly_separated?(current_route, next_route)
          current_end_line = current_route[:end_line]
          next_start_line = next_route[:line]
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
