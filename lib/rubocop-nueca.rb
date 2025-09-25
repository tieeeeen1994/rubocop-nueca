# frozen_string_literal: true

require_relative 'rubocop/nueca/version'
require 'rubocop'

# Load the plugin
require_relative 'rubocop/nueca/plugin'

# Load all custom cops
['rails', 'rswag'].each do |subdir|
  Dir[File.join(__dir__, 'rubocop', 'cop', subdir, '*.rb')].each do |file|
    require file
  end
end
