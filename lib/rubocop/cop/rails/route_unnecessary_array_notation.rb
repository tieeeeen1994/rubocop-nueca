# frozen_string_literal: true

require_relative '../shared/route_helper'

module RuboCop
  module Cop
    module Rails
      class RouteUnnecessaryArrayNotation < RuboCop::Cop::Base
        include RouteHelper
        extend AutoCorrector

        MSG = 'Unnecessary array notation for single element. ' \
              'Use `%<key>s: %<value>s` instead of `%<key>s: [%<value>s]`.'

        def on_send(node)
          return unless route_file?
          return unless route_method?(node)

          node.arguments.each do |arg|
            next unless arg.hash_type?

            check_hash_pairs(arg)
          end
        end

        private

        def route_method?(node)
          return false unless node.send_type?

          route_methods = [
            :get, :post, :put, :patch, :delete, :head, :options, :match, :root,
            :resource, :resources,
            :namespace, :scope, :concern, :member, :collection,
            :draw
          ]

          route_methods.include?(node.method_name)
        end

        def check_hash_pairs(hash_node)
          hash_node.pairs.each do |pair|
            check_single_element_array(pair)
          end
        end

        def check_single_element_array(pair)
          value = pair.value
          return unless value.array_type?
          return unless value.children.size == 1

          element = value.children.first
          return unless element.sym_type? || element.str_type?

          key = pair.key
          key_source = key.source
          element_source = element.source

          message = format(
            MSG,
            key: key_source,
            value: element_source
          )

          add_offense(value, message: message) do |corrector|
            corrector.replace(value, element_source)
          end
        end
      end
    end
  end
end
