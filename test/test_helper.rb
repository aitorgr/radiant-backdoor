# Load the the environment
unless defined? RADIANT_ROOT
  ENV["RAILS_ENV"] = "test"
  boot_file = "#{File.expand_path(File.dirname(__FILE__) + "/../../../../")}/config/boot"
  raise "Tests for this extension must be executed when it's properly installed in a radiant app" unless File.exist?( boot_file + ".rb")
  require boot_file
end
require "#{RADIANT_ROOT}/test/test_helper"

class Test::Unit::TestCase
  
  # Include a helper to make testing Radius tags easier
  test_helper :extension_tags
  
  # Add the fixture directory to the fixture path
  self.fixture_path << File.dirname(__FILE__) + "/fixtures"
  
  # Add more helper methods to be used by all extension tests here...
  
end
