# encoding: utf-8
require 'spec_helper'

describe Mongoid::Globalize do
  it "has locale accessors" do
    Mongoid::Globalize.should respond_to(:locale)
    Mongoid::Globalize.should respond_to(:locale=)
  end

  describe "#locale reader" do
    it "can be called before a locale was set" do
      Mongoid::Globalize.locale = nil
      lambda{ Mongoid::Globalize.locale }.should_not raise_error
    end
  end

  describe 'locale setting' do
    it "works" do
      I18n.locale.should == :en
      Mongoid::Globalize.locale.should == :en

      I18n.locale = :de
      I18n.locale.should == :de
      Mongoid::Globalize.locale.should == :de

      Mongoid::Globalize.locale = :es
      I18n.locale.should == :de
      Mongoid::Globalize.locale.should == :es

      I18n.locale = :fr
      I18n.locale.should == :fr
      Mongoid::Globalize.locale.should == :es
    end

    it "works with strings" do
      I18n.locale = 'de'
      Mongoid::Globalize.locale = 'de'
      Mongoid::Globalize.locale.should == I18n.locale

      I18n.locale = 'de'
      Mongoid::Globalize.locale = :de
      Mongoid::Globalize.locale.should == I18n.locale

      I18n.locale =  :de
      Mongoid::Globalize.locale = 'de'
      Mongoid::Globalize.locale.should == I18n.locale
    end
  end
  
  describe "with_locale" do
    it "temporarily sets the given locale and yields the block" do
      Mongoid::Globalize.locale.should == :en
      Mongoid::Globalize.with_locale :de do |locale|
        Mongoid::Globalize.locale.should == :de
        locale.should == :de
      end
      Mongoid::Globalize.locale.should == :en
    end

    it "calls block once with each locale given temporarily set" do
      locales = Mongoid::Globalize.with_locales :en, [:de, :fr] do |locale|
        Mongoid::Globalize.locale.should == locale
        locale
      end
      locales.should == [:en, :de, :fr]
    end
  end

  describe "attribute saving" do
    it "goes by content locale and not global locale" do
      Mongoid::Globalize.locale = :de
      I18n.locale.should == :en
      Post.create :title => 'foo'
      Post.first.translations.first.locale.should == :de
    end
  end

  describe "attribute loading" do
    it "goes by content locale and not global locale" do
      post = Post.create(:title => 'title')
      Post.first.should be_translated(:en).for(:title).as('title')

      Mongoid::Globalize.locale = :de
      post.update_attributes(:title => 'Titel')
      Post.first.should be_translated(:en).for(:title).as('title')
      Post.first.should be_translated(:de).for(:title).as('Titel')
    end
  end
end
