# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      class ModelAssociationSorting < RuboCop::Cop::Base # rubocop:disable Metrics/ClassLength
        MSG = 'Sort associations of the same type alphabetically. Expected order: %<expected>s.'
        ASSOCIATION_METHODS = [
          :belongs_to,
          :has_one,
          :has_many,
          :has_and_belongs_to_many
        ].freeze

        def on_class(node)
          return unless model_class?(node)

          associations = find_associations(node)
          return if associations.size < 2

          check_association_sorting(associations)
        end

        private

        def model_class?(node)
          parent_class = node.parent_class
          return false unless parent_class

          parent_name = parent_class.const_name
          ['ApplicationRecord', 'ActiveRecord::Base'].include?(parent_name)
        end

        def find_associations(class_node)
          associations = []

          class_node.body&.each_child_node do |child|
            next unless child.type == :send
            next unless association_method?(child)

            source_range = child.source_range
            associations << {
              node: child,
              method: child.method_name,
              name: association_name(child),
              through: association_through(child),
              start_line: source_range.line,
              end_line: source_range.last_line
            }
          end

          associations.sort_by { |assoc| assoc[:start_line] }
        end

        def association_method?(node)
          return false unless node.receiver.nil?

          ASSOCIATION_METHODS.include?(node.method_name)
        end

        def association_name(node)
          first_arg = node.arguments.first
          return nil unless first_arg&.sym_type?

          first_arg.value.to_s
        end

        def association_through(node)
          options_hash = find_options_hash(node)
          return nil unless options_hash

          through_pair = options_hash.pairs.find do |pair|
            pair.key.sym_type? && pair.key.value == :through
          end

          return nil unless through_pair&.value&.sym_type?

          through_pair.value.value.to_s
        end

        def find_options_hash(node)
          node.arguments.find(&:hash_type?)
        end

        def check_association_sorting(associations)
          grouped = associations.group_by { |assoc| assoc[:method] }

          grouped.each_value do |group_associations|
            next if group_associations.size < 2

            check_group_sorting(group_associations)
          end
        end

        def check_group_sorting(group_associations)
          through_associations = group_associations.select { |assoc| assoc[:through] }
          regular_associations = group_associations.reject { |assoc| assoc[:through] }

          regular_sorted = regular_associations.sort_by { |assoc| assoc[:name] }

          expected_order = build_expected_order(regular_sorted, through_associations)
          actual_order = group_associations.map { |assoc| assoc[:name] }

          return if actual_order == expected_order

          expected_order_str = expected_order.join(', ')
          message = format(MSG, expected: expected_order_str)

          add_offense(group_associations.first[:node], message: message)
        end

        def build_expected_order(regular_associations, through_associations)
          all_associations = regular_associations + through_associations
          association_lookup = build_association_lookup(all_associations)
          dependency_graph = build_dependency_graph(all_associations, association_lookup)

          topological_sort_alphabetically(dependency_graph, all_associations.map { |a| a[:name] })
        end

        def build_association_lookup(associations)
          associations.index_by { |assoc| assoc[:name] }
        end

        def build_dependency_graph(associations, lookup)
          graph = associations.each_with_object({}) { |assoc, deps| deps[assoc[:name]] = [] }

          associations.each do |assoc|
            graph[assoc[:through]] << assoc[:name] if assoc[:through] && lookup[assoc[:through]]
          end

          graph
        end

        def topological_sort_alphabetically(dependency_graph, all_nodes)
          in_degrees = calculate_in_degrees(dependency_graph, all_nodes)
          available_nodes = nodes_with_zero_dependencies(in_degrees)
          result = []

          until available_nodes.empty?
            current = available_nodes.shift
            result << current

            process_dependents(current, dependency_graph, in_degrees, available_nodes)
          end

          result
        end

        def calculate_in_degrees(dependency_graph, all_nodes)
          in_degrees = all_nodes.each_with_object({}) { |node, degrees| degrees[node] = 0 }

          dependency_graph.each_value do |dependents|
            dependents.each { |dependent| in_degrees[dependent] += 1 }
          end

          in_degrees
        end

        def nodes_with_zero_dependencies(in_degrees)
          in_degrees.select { |_node, degree| degree.zero? }.keys.sort
        end

        def process_dependents(current_node, dependency_graph, in_degrees, available_nodes)
          dependency_graph[current_node]&.each do |dependent|
            in_degrees[dependent] -= 1

            insert_alphabetically(available_nodes, dependent) if in_degrees[dependent].zero?
          end
        end

        def insert_alphabetically(sorted_array, element)
          insert_position = sorted_array.bsearch_index { |x| x > element } || sorted_array.length
          sorted_array.insert(insert_position, element)
        end
      end
    end
  end
end
