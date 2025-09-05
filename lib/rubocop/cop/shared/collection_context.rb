# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      class CollectionContext
        ROUTE_CATEGORIES = {
          simple: [:get, :post, :put, :patch, :delete, :head, :options, :match, :root],
          resource: [:resource, :resources],
          namespace: [:namespace, :scope, :concern],
          draw: [:draw]
        }.freeze

        ALL_ROUTE_METHODS = ROUTE_CATEGORIES.values.flatten.freeze

        def initialize(collector, namespace_level, namespace_path = [])
          @collector = collector
          @namespace_level = namespace_level
          @namespace_path = namespace_path
        end

        def process_node(node)
          case node.type
          when :begin
            node.children.each { |child| process_node(child) }
          when :send
            add_route_if_valid(node)
          when :block
            process_block(node)
          end
        end

        private

        def add_route_if_valid(node)
          return unless route_method?(node)

          route_info = build_route_info(node)
          @collector.add_route(route_info) if route_info
        end

        def process_block(node)
          send_node = node.send_node
          return unless send_node.send_type? && route_method?(send_node)

          add_route_if_valid(send_node)

          body = node.body
          return unless body

          new_namespace_path = @namespace_path.dup
          if send_node.method_name == :namespace
            namespace_name = extract_namespace_name(send_node)
            new_namespace_path << namespace_name if namespace_name
          end

          nested_context = CollectionContext.new(@collector, @namespace_level + 1, new_namespace_path)
          nested_context.process_node(body)
        end

        def extract_namespace_name(node)
          first_arg = node.arguments.first
          return first_arg.value.to_s if first_arg&.sym_type? || first_arg&.str_type?

          'unknown'
        end

        def route_method?(node)
          return false unless node.send_type?

          receiver = node.receiver
          return false if receiver && !simple_receiver?(receiver)

          ALL_ROUTE_METHODS.include?(node.method_name)
        end

        def simple_receiver?(receiver)
          receiver.nil? || receiver.send_type?
        end

        def build_route_info(node)
          method_name = node.method_name
          route_name = extract_route_name(node)
          return nil unless route_name

          source_range = node.source_range
          {
            node: node,
            method: method_name,
            name: route_name,
            line: source_range.line,
            end_line: source_range.last_line,
            namespace_level: @namespace_level,
            namespace_path: @namespace_path.dup,
            type: categorize_route_method(method_name)
          }
        end

        def extract_route_name(node)
          method_name = node.method_name
          first_arg = node.arguments.first

          case method_name
          when :root then 'root'
          when :draw then extract_symbol_or_default(first_arg, 'draw')
          when *ROUTE_CATEGORIES[:simple] then extract_simple_route_name(first_arg)
          when *ROUTE_CATEGORIES[:resource], *ROUTE_CATEGORIES[:namespace]
            extract_symbol_or_default(first_arg, 'unknown')
          else
            'unknown'
          end
        end

        def extract_symbol_or_default(arg, default)
          arg&.sym_type? ? arg.value.to_s : default
        end

        def extract_simple_route_name(first_arg)
          return first_arg.value.to_s if first_arg&.str_type?
          return extract_hash_route_name(first_arg) if first_arg&.hash_type?

          'unknown'
        end

        def extract_hash_route_name(hash_arg)
          first_pair = hash_arg.pairs.first
          first_pair&.key&.value&.to_s || 'unknown' # rubocop:disable Style/SafeNavigationChainLength
        end

        def categorize_route_method(method_name)
          ROUTE_CATEGORIES.each do |category, methods|
            return category if methods.include?(method_name)
          end
          :other
        end
      end
    end
  end
end
