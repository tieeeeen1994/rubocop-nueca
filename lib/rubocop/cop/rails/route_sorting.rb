# frozen_string_literal: true

require_relative '../shared/route_collector'

module RuboCop
  module Cop
    module Rails
      class RouteSorting < RuboCop::Cop::Base
        MSG = 'Sort routes of the same type alphabetically within the same namespace level. ' \
              'Expected order: %<expected>s.'

        def on_block(node)
          return unless rails_routes_draw_block?(node)

          routes = collect_routes(node)
          return if routes.size < 2

          check_route_sorting(routes)
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

        def check_route_sorting(routes)
          grouped_routes = routes.group_by do |route|
            [route[:type], route[:namespace_level], route[:namespace_path]]
          end

          grouped_routes.each_value do |group_routes|
            next if group_routes.size < 2

            check_group_sorting(group_routes)
          end
        end

        def check_group_sorting(group_routes)
          non_root_routes = group_routes.reject { |route| root_route?(route) }
          return if non_root_routes.size < 2

          route_names = non_root_routes.map { |route| route[:name] }
          sorted_names = route_names.sort

          return if route_names == sorted_names

          expected_order = sorted_names.uniq.join(', ')
          message = format(MSG, expected: expected_order)

          add_offense(non_root_routes.first[:node], message: message)
        end

        def root_route?(route)
          route[:name] == 'root'
        end
      end
    end
  end
end
