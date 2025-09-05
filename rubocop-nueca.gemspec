# frozen_string_literal: true

require_relative 'lib/rubocop/nueca/version'

Gem::Specification.new do |spec|
  spec.name = 'rubocop-nueca'
  spec.version = RuboCop::Nueca::VERSION
  spec.authors = ['TODO: Write your name']
  spec.email = ['TODO: Write your email address']

  spec.summary = 'TODO: Write a short summary, because RubyGems requires one.'
  spec.description = 'TODO: Write a longer description or delete this line.'
  spec.homepage = 'https://github.com/tieeeeen1994/rubocop-nueca'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['allowed_push_host'] = "TODO: Set to your gem server 'https://example.com'"
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/tieeeeen1994/rubocop-nueca'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(['git', 'ls-files', '-z'], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?('bin/', 'Gemfile', '.gitignore', '.rubocop.yml')
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Plugin configuration
  spec.metadata['default_lint_roller_plugin'] = 'RuboCop::Nueca::Plugin'

  # Dependencies
  spec.add_dependency 'lint_roller'
  spec.add_dependency 'rubocop', '>= 1.72.0'
  spec.add_dependency 'rubocop-capybara'
  spec.add_dependency 'rubocop-rails'
  spec.add_dependency 'rubocop-rspec'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata['rubocop_extension'] = 'true'
end
