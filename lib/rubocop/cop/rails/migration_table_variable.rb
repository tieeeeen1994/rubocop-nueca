# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      class MigrationTableVariable < RuboCop::Cop::Base
        MSG = 'Use `t` as the variable name for table operations in migrations.'

        def_node_matcher :create_table_block, <<~PATTERN
          (block (send nil? :create_table ...) (args (arg $_)) ...)
        PATTERN

        def_node_matcher :change_table_block, <<~PATTERN
          (block (send nil? :change_table ...) (args (arg $_)) ...)
        PATTERN

        def on_block(node)
          return unless in_migration_file?

          variable_name = extract_table_variable(node)
          return unless variable_name
          return if variable_name == :t

          add_offense(node.arguments.first, message: MSG)
        end

        private

        def extract_table_variable(node)
          create_table_block(node) ||
            change_table_block(node)
        end

        def in_migration_file?
          processed_source.file_path&.include?('db/migrate/') || false
        end
      end
    end
  end
end
