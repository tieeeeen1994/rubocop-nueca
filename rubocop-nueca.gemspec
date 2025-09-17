# frozen_string_literal: true

require_relative 'lib/rubocop/nueca/version'

Gem::Specification.new do |spec|
  spec.name = 'rubocop-nueca'
  spec.version = RuboCop::Nueca::VERSION
  spec.authors = ['Tien']
  spec.email = ['tieeeeen1994@gmail.com']

  spec.summary = 'This enforces custom rules for Nueca according to culture.'
  spec.homepage = 'https://github.com/tieeeeen1994/rubocop-nueca'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['source_code_uri'] = 'https://github.com/tieeeeen1994/rubocop-nueca'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(['git', 'ls-files', '-z'], chdir: __dir__, err: IO::NULL) do |ls|
    ls.each_line("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?('bin/', 'Gemfile', '.gitignore', '.rubocop.yml')
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Plugin configuration
  spec.metadata['default_lint_roller_plugin'] = 'RuboCop::Nueca::Plugin'
  spec.metadata['rubocop_extension'] = 'true'

  # Dependencies
  spec.add_dependency 'lint_roller'
  spec.add_dependency 'rubocop'
  spec.add_dependency 'rubocop-capybara'
  spec.add_dependency 'rubocop-factory_bot'
  spec.add_dependency 'rubocop-performance'
  spec.add_dependency 'rubocop-rails'
  spec.add_dependency 'rubocop-rspec'
  spec.add_dependency 'rubocop-rspec_rails'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
