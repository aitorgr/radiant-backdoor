namespace :radiant do
  namespace :extensions do
    namespace :back_door do
      
      desc "Runs the migration of the Back Door extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          BackDoorExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          BackDoorExtension.migrator.migrate
        end
      end
    
    end
  end
end