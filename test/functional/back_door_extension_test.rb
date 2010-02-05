require File.dirname(__FILE__) + '/../test_helper'

class BackDoorExtensionTest < Test::Unit::TestCase
  
  def test_this_extension
    assert true
  end
  
=begin
  def test_initialization
    assert_equal File.join(File.expand_path(RAILS_ROOT), 'vendor', 'extensions', 'back_door'), BackDoorExtension.root
    assert_equal 'Back Door', BackDoorExtension.extension_name
  end
=end
  
end
