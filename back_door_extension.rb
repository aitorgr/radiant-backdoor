require "lib/back_door.rb"

class BackDoorExtension < Radiant::Extension
  version       IO.read( File.join( File.dirname( __FILE__), "VERSION")).strip
  description   "Provides tags to execute arbitrary ruby code directly"
  url           "http://backdoor.rubyforge.org/"
  
  def activate
    unless Page.include?( BackDoorTags)
        Page.send :include, BackDoorTags              # add our tags
    end
    unless Radius::TagBinding.include?( BackDoor)
        Radius::TagBinding.send :remove_method, :attr # remove "attr" accesor
        Radius::TagBinding.send :include, BackDoor    # add our own "attr" accesor
    end
  end
  
  def deactivate
    # *toDO* deactivate the extension properly
  end

end
