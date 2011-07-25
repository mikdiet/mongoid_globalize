# encoding: utf-8
require 'spec_helper'

describe "Fallbacks" do
  before :each do
    @previous_backend = I18n.backend
    I18n.pretend_fallbacks
    I18n.backend = BackendWithFallbacks.new

    I18n.locale = :'en-US'
    I18n.fallbacks = ::I18n::Locale::Fallbacks.new
  end

  after :each do
    I18n.fallbacks.clear
    I18n.hide_fallbacks
    I18n.backend = @previous_backend
  end

  it "keep one field in new locale when other field is changed" do
    I18n.fallbacks.map('de-DE' => [ 'en-US' ])
    post = Post.create :title => 'foo'
    I18n.locale = 'de-DE'
    post.content = 'bar'
    post.title.should == 'foo'
  end

  it "modify non-required field in a new locale" do
    I18n.fallbacks.map 'de-DE' => [ 'en-US' ]
    post = Post.create :title => 'foo'
    I18n.locale = 'de-DE'
    post.content = 'bar'
    post.save.should be_true
  end

  it "resolve a simple fallback" do
    I18n.locale = 'de-DE'
    post = Post.create :title => 'foo'

    I18n.locale = 'de'
    post.title = 'baz'
    post.content = 'bar'
    post.save!

    I18n.locale = 'de-DE'
    post.title.should == 'foo'
    post.content.should == 'bar'
  end

  it "resolve a simple fallback without reloading" do
    I18n.locale = 'de-DE'
    post = Post.new :title => 'foo'

    I18n.locale = 'de'
    post.title = 'baz'
    post.content = 'bar'

    I18n.locale = 'de-DE'
    post.title.should == 'foo'
    post.content.should == 'bar'
  end

  it "resolve a complex fallback without reloading" do
    I18n.fallbacks.map 'de' => %w(en he)
    I18n.locale = 'de'
    post = Post.new
    I18n.locale = 'en'
    post.title = 'foo'
    I18n.locale = 'he'
    post.title = 'baz'
    post.content = 'bar'
    I18n.locale = 'de'
    post.title.should == 'foo'
    post.content.should == 'bar'
  end

  it 'work with lots of locale switching' do
    I18n.fallbacks.map :'de-DE' => [ :'en-US' ]
    post = Post.create :title => 'foo'
    I18n.locale = :'de-DE'
    post.title.should == 'foo'

    I18n.locale = :'en-US'
    post.update_attributes(:title => 'bar')
    I18n.locale = :'de-DE'
    post.title.should == 'bar'
  end

  it 'work with lots of locale switching 2' do
    I18n.fallbacks.map :'de-DE' => [ :'en-US' ]
    child = Child.create :content => 'foo'
    I18n.locale = :'de-DE'
    child.content.should == 'foo'

    I18n.locale = :'en-US'
    child.update_attributes(:content => 'bar')
    I18n.locale = :'de-DE'
    child.content.should == 'bar'
  end

  it 'work with nil translations' do
    I18n.fallbacks.map :'de-DE' => [ :'en-US' ]
    post = Post.create :title => 'foo'
    I18n.locale = :'de-DE'
    post.title.should == 'foo'

    post.update_attribute :title, nil
    post.title.should == 'foo'
  end

  it 'work with empty translations' do
    I18n.fallbacks.map :'de-DE' => [ :'en-US' ]
    task = Task.create :name => 'foo'
    I18n.locale = :'de-DE'
    task.name.should == 'foo'

    task.update_attribute :name, ''
    task.name.should == 'foo'
  end

  it 'work with empty translations 2' do
    I18n.fallbacks.map :'de-DE' => [ :'en-US' ]
    task = Task.create :name => 'foo'
    post = Post.create :title => 'foo'
    I18n.locale = :'de-DE'
    task.name.should == 'foo'
    post.title.should == 'foo'

    task.update_attribute :name, ''
    task.name.should == 'foo'

    post.update_attribute :title, ''
    post.title.should == ''
  end
end
