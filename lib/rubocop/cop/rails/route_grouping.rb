# frozen_string_literal: true

require_relative '../shared/route_collector'

module RuboCop
  module Cop
    module Rails
      class RouteGrouping < RuboCop::Cop::Base
        MSG = 'Group routes by type. Keep simple routes, resources, and namespaces grouped together.'

        def on_block(node)
          return unless rails_routes_draw_block?(node)

          routes = collect_routes(node)
          return if routes.size < 2

          check_for_scattered_routes(routes)
        end

        private

        def rails_routes_draw_block?(node)
          return false unless node.block_type?

          send_node = node.send_node
          receiver = send_node.receiver
          return false unless receiver

          receiver.source == 'Rails.application.routes' && send_node.method_name == :draw
        end

        def collect_routes(routes_block)
          collector = RouteCollector.new
          body = routes_block.body
          collector.collect(body) if body
          collector.routes.sort_by { |route| route[:line] }
        end

        def check_for_scattered_routes(routes)
          routes_by_type_and_context = routes.group_by do |route|
            [route[:type], route[:namespace_level], route[:namespace_path]]
          end

          routes_by_type_and_context.each_value do |type_routes|
            next if type_routes.size < 2

            find_scattered_routes(type_routes, routes).each do |route|
              add_offense(route[:node], message: MSG)
            end
          end
        end

        def find_scattered_routes(type_routes, all_routes)
          scattered = []

          type_routes.each_with_index do |current_route, index|
            next if index.zero?

            if scattered_from_previous?(current_route, type_routes[0...index],
                                        all_routes) && !scattered.include?(current_route) # rubocop:disable Rails/NegateInclude
              scattered << current_route
            end
          end

          scattered
        end

        def scattered_from_previous?(current_route, previous_routes, all_routes)
          current_line = current_route[:line]
          route_type = current_route[:type]
          namespace_level = current_route[:namespace_level]

          previous_routes.any? do |prev_route|
            different_types_between?(all_routes, prev_route[:line], current_line, route_type, namespace_level)
          end
        end

        def different_types_between?(all_routes, start_line, end_line, route_type, namespace_level)
          all_routes.any? do |route|
            line = route[:line]
            line > start_line && line < end_line &&
              route[:namespace_level] == namespace_level && route[:type] != route_type
          end
        end
      end
    end
  end
end
