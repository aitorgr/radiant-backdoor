require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the back_door extension.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

task :rdoc => :post_rdoc
task :post_rdoc => :real_rdoc
task :real_rdoc => :pre_rdoc

desc 'Generate documentation for the back_door extension.'
Rake::RDocTask.new(:real_rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'BackDoorExtension'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('VERSION')
  rdoc.rdoc_files.include('TODO')
  rdoc.rdoc_files.include('CHANGELOG')
  rdoc.rdoc_files.include('MIT-LICENSE')
  rdoc.rdoc_files.include('**/*.rb')
end

task :pre_rdoc do |task|
  # preprocess README file with erb
  sh "erb README.erb > README", :verbose => false
  # all this rdoc directory trashing is to preserve .svn directories (RDoc deletes original 'rdoc' directory)
  sh "mv rdoc rdoc.old", :verbose => false
end

# undo things done in :pre_rdoc task
task :post_rdoc do |task|
  sh "cp -R rdoc/* rdoc.old/", :verbose => false
  sh "rm -rf rdoc", :verbose => false
  sh "mv rdoc.old rdoc", :verbose => false
end

# Load any custom rakefiles for extension
Dir[File.dirname(__FILE__) + '/tasks/*.rake'].sort.each { |f| require f }
