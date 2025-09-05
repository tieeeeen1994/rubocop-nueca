# frozen_string_literal: true

require_relative 'nueca/version'
require 'rubocop'

# Load the plugin
require_relative 'rubocop/nueca/plugin'

# Load all custom Rails cops
Dir[File.join(__dir__, 'rubocop', 'cop', 'rails', '*.rb')].each do |file|
  require file
end
