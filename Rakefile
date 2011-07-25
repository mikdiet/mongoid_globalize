# encoding: UTF-8
require 'rubygems'
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rake'
require 'rdoc/task'

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'TranslationPanel'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "mongoid_globalize"
  gem.homepage = "http://github.com/Mik-die/mongoid_globalize"
  gem.license = "MIT"
  gem.summary = %Q{Library for translating Mongoid documents}
  gem.description = %Q{Library for translating Mongoid documents, based on Globalize3 principles}
  gem.email = "MikDiet@gmail.com"
  gem.authors = ["Mik-die"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new
