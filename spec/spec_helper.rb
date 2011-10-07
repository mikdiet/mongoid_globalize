require 'rubygems'
require "bundler/setup"
require 'mongoid'

Mongoid.configure do |config|
  name = "mongoid_globalize_test"
  config.autocreate_indexes = true
  db = Mongo::Connection.new.db(name)
  db.add_user("mongoid", "test")
  config.master = db
  config.logger = Logger.new($stdout, :warn)
end

require 'mongoid_globalize'
require File.expand_path('../data/models', __FILE__)

require 'rspec'
require 'database_cleaner'
require 'mongoid-rspec'
RSpec.configure do |config|
  config.include Mongoid::Matchers
  config.before :suite do
    DatabaseCleaner.strategy = :truncation
  end

  config.before :each do
    I18n.locale = :en
  end

  config.after :each do
    DatabaseCleaner.clean
    # because rspec run all specs in one thread
    Thread.current[:globalize_locale] = nil
  end
end

def with_locale(*args, &block)
  Mongoid::Globalize.with_locale(*args, &block)
end

RSpec::Matchers.define :be_translated do |locale|
  chain :for do |attributes|
    @attributes = Array.wrap(attributes)
  end

  chain :as do |translations|
    @translations = Array.wrap(translations)
  end

  match do |record|
    @result = @attributes.map{|name| record.send(name, locale)}
    @result == @translations
  end

  failure_message_for_should do |record|
    "expected that attributes #{@attributes.inspect} for #{record} in " +
    "#{locale.inspect} locale should be #{@translations.inspect}.\n" +
    "  Diff:\n    -#{@translations.inspect}\n    +#{@result.inspect}"
  end
end

class BackendWithFallbacks < I18n::Backend::Simple
  include I18n::Backend::Fallbacks
end

meta = class << I18n; self; end
meta.class_eval do
  alias_method(:alternatives, :fallbacks)

  def pretend_fallbacks
    class << I18n; self; end.send(:alias_method, :fallbacks, :alternatives)
  end

  def hide_fallbacks
    class << I18n; self; end.send(:remove_method, :fallbacks)
  end
end

I18n.hide_fallbacks
