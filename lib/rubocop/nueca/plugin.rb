# frozen_string_literal: true

require 'lint_roller'

module RuboCop
  module Nueca
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: 'rubocop-nueca',
          version: VERSION,
          homepage: 'https://github.com/tieeeeen1994/rubocop-nueca',
          description: 'Custom RuboCop rules for Nueca according to culture.'
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: Pathname.new(__dir__).join('../../../config/default.yml')
        )
      end
    end
  end
end
