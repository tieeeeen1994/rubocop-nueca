# frozen_string_literal: true

require_relative '../shared/route_helper'

module RuboCop
  module Cop
    module Rails
      class RouteRootPosition < RuboCop::Cop::Base
        include RouteHelper

        MSG = 'The root route should be positioned at the top of routes within the same namespace level.'

        def on_block(node)
          process_route_block(node)
        end

        def investigate(processed_source)
          process_route_file(processed_source)
        end

        private

        def minimum_routes_for_check
          0
        end

        def check_routes(routes)
          return if routes.empty?

          check_root_position(routes)
        end

        def check_root_position(routes)
          routes_by_context = routes.group_by do |route|
            [route[:namespace_level], route[:namespace_path]]
          end

          routes_by_context.each_value do |context_routes|
            check_root_in_context(context_routes)
          end
        end

        def check_root_in_context(context_routes)
          return if context_routes.size < 2

          root_routes, non_root_routes = partition_routes_by_root(context_routes)
          return if root_routes.empty?

          non_root_simple_routes = filter_simple_routes(non_root_routes)
          return if non_root_simple_routes.empty?

          detect_mispositioned_roots(root_routes, non_root_simple_routes)
        end

        def filter_simple_routes(routes)
          routes.select { |route| simple_route?(route) }
        end

        def detect_mispositioned_roots(root_routes, simple_routes)
          root_routes.each do |root_route|
            if any_simple_route_before?(root_route, simple_routes)
              add_offense(root_route[:node], message: MSG)
              break
            end
          end
        end

        def any_simple_route_before?(root_route, simple_routes)
          simple_routes.any? { |simple_route| root_route[:line] > simple_route[:line] }
        end

        def partition_routes_by_root(routes)
          root_routes = []
          non_root_routes = []

          routes.each do |route|
            if root_route?(route)
              root_routes << route
            else
              non_root_routes << route
            end
          end

          [root_routes, non_root_routes]
        end

        def root_route?(route)
          route[:name] == 'root'
        end

        def simple_route?(route)
          route[:type] == :simple
        end
      end
    end
  end
end
