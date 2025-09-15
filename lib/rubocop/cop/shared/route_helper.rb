# frozen_string_literal: true

require_relative 'route_collector'

module RuboCop
  module Cop
    module Rails
      module RouteHelper
        def route_file?
          processed_source.file_path&.end_with?('routes.rb')
        end

        def route_block?(node)
          return false unless node.block_type?

          send_node = node.send_node
          return false unless send_node.send_type?
          return true if send_node.receiver&.source == 'Rails.application.routes' && send_node.method_name == :draw
          return false unless route_file?

          [:scope, :namespace, :concern].include?(send_node.method_name)
        end

        def collect_routes(routes_block)
          collector = RouteCollector.new
          body = routes_block.body
          collector.collect(body) if body
          collector.routes.sort_by { |route| route[:line] }
        end

        def collect_routes_from_file(ast_node)
          collector = RouteCollector.new
          collector.collect(ast_node) if ast_node
          collector.routes.sort_by { |route| route[:line] }
        end

        def process_route_block(node)
          return unless route_block?(node)

          routes = collect_routes(node)
          return if routes.size < minimum_routes_for_check

          check_routes(routes)
        end

        def process_route_file(processed_source)
          return unless route_file?
          return if processed_source.ast.nil?

          routes = collect_routes_from_file(processed_source.ast)
          return if routes.size < minimum_routes_for_check

          check_routes(routes)
        end

        private

        def minimum_routes_for_check
          2
        end

        def check_routes(routes)
          raise NotImplementedError, 'Subclasses must implement check_routes method'
        end
      end
    end
  end
end
