# frozen_string_literal: true

# :nocov:
module CustomCop
  module Rails
    class MongoidNeeds < RuboCop::Cop::Base
      extend RuboCop::Cop::AutoCorrector

      SAFETY = :unsafe
      MSG = 'Add `needs: :mongoid` to RSpec.describe when requiring mongoid_helper.'

      def_node_matcher :require_mongoid_helper, <<~PATTERN
        (send nil? :require (str "mongoid_helper"))
      PATTERN

      def_node_matcher :rspec_describe_with_needs, <<~PATTERN
        (send
          (const nil? :RSpec) :describe
          _
          (hash <(pair (sym :needs) (sym :mongoid)) ...>))
      PATTERN

      def_node_matcher :rspec_describe_without_needs, <<~PATTERN
        (send
          (const nil? :RSpec) :describe
          _
          $...)
      PATTERN

      def on_send(node)
        buffer = node.source_range.source_buffer
        return unless buffer.name.include?('_spec.rb')
        return unless require_mongoid_helper(node)

        root_node = processed_source.ast
        describe_node = find_rspec_describe(root_node)

        return unless describe_node
        return if rspec_describe_with_needs(describe_node)

        add_offense(describe_node, message: MSG) do |corrector|
          autocorrect(corrector, describe_node)
        end
      end

      private

      def find_rspec_describe(node)
        return node if rspec_describe_without_needs(node)

        node.children.each do |child|
          next unless child.is_a?(Parser::AST::Node)

          result = find_rspec_describe(child)
          return result if result
        end

        nil
      end

      def autocorrect(corrector, node)
        args = node.arguments
        last_arg = args.last
        if args.size == 2 && last_arg.hash_type?
          hash_node = last_arg
          last_pair = hash_node.pairs.last

          if last_pair
            corrector.insert_after(last_pair, ', needs: :mongoid')
          else
            corrector.insert_after(hash_node.loc.begin, 'needs: :mongoid')
          end
        else
          corrector.insert_after(last_arg, ', needs: :mongoid')
        end
      end
    end
  end
end
# :nocov:
