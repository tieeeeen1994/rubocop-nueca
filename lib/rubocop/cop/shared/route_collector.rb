# frozen_string_literal: true

require_relative 'collection_context'

module RuboCop
  module Cop
    module Rails
      class RouteCollector
        attr_reader :routes

        def initialize
          @routes = []
        end

        def collect(node, namespace_level = 0, namespace_path = [])
          context = CollectionContext.new(self, namespace_level, namespace_path)
          context.process_node(node)
        end

        def add_route(route_info)
          @routes << route_info
        end
      end
    end
  end
end
