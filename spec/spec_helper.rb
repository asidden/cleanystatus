$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "aruba"
require "aruba/rspec"
require "cleanystatus"

Aruba.configure do |config|
  config.command_search_paths.push "exe"
end

RSpec.configure do |config|
  # config.filter_run :focus
  # config.run_all_when_everything_filtered = true
end

# def aruba_run
#   setup_aruba
#   directory = "../exe"
#
#   yield
#
#   stop_all_commands
#   sleep(1)
#   return last_command_output
# end
