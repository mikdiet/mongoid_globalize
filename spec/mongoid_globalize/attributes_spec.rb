# encoding: utf-8
require 'spec_helper'

describe 'Attributes' do
  it "defines accessors for the translated attributes" do
    post = Post.new
    post.should respond_to(:title)
    post.should respond_to(:title=)
  end

  describe "attribute_names" do
    it "returns translated and existing attribute names" do
      Post.new(:blog_id => 5).attribute_names.should include('blog_id', 'content', 'title')
    end
  end

  it "returns translated and regular attributes" do
    post = Post.create(:title => 'foo', :blog_id => 5)
    post.attributes.should include('blog_id' => 5, 'title' => 'foo', 'content' => nil)
  end

  describe "write_attribute for non-translated attributes" do
    it "should return the value" do
      user = User.create(:name => 'Max Mustermann', :email => 'max@mustermann.de')
      new_email = 'm.muster@mann.de'
      user.write_attribute('email', new_email).should == new_email
    end
  end

  describe "translated_attribute_names" do
    it "returns translated attribute names" do
      Post.translated_attribute_names.should include(:title, :content)
    end
  end

  describe "a translated attribute" do
    describe "writer" do
      it "returns its argument" do
        (Post.new.title = 'foo').should == 'foo'
      end
    end

    describe "reader" do
      it "returns the correct translation for a saved record after locale switching" do
        post = Post.create(:title => 'title')
        post.update_attributes(:title => 'Titel', :locale => :de)
        post.reload
        post.should be_translated(:en).for(:title).as('title')
        post.should be_translated(:de).for(:title).as('Titel')
      end

      it "returns the correct translation for an unsaved record after locale switching" do
        post = Post.create(:title => 'title')
        with_locale(:de) { post.title = 'Titel' }
        post.should be_translated(:en).for(:title).as('title')
        post.should be_translated(:de).for(:title).as('Titel')
      end

      it "returns the correct translation for both saved/unsaved records while switching locales" do
        post = Post.new(:title => 'title')
        with_locale(:de) { post.title = 'Titel' }
        with_locale(:he) { post.title = 'שם' }
        post.should be_translated(:de).for(:title).as('Titel')
        post.should be_translated(:he).for(:title).as('שם')
        post.should be_translated(:en).for(:title).as('title')
        post.should be_translated(:he).for(:title).as('שם')
        post.should be_translated(:de).for(:title).as('Titel')

        post.save
        post.reload
        post.should be_translated(:de).for(:title).as('Titel')
        post.should be_translated(:he).for(:title).as('שם')
        post.should be_translated(:en).for(:title).as('title')
        post.should be_translated(:he).for(:title).as('שם')
        post.should be_translated(:de).for(:title).as('Titel')
      end

      it "returns nil if no translations are found on an unsaved record" do
        post = Post.new(:title => 'foo')
        post.title.should == 'foo'
        post.content.should be_nil
      end

      it "returns nil if no translations are found on a saved record" do
        post = Post.create(:title => 'foo')
        post.reload
        post.title.should == 'foo'
        post.content.should be_nil
      end
    end
  end

  describe "before_type_cast reader" do
    it "works for translated attributes" do
      post = Post.create(:title => 'title')
      post.update_attributes(:title => "Titel", :locale => :de)
  
      with_locale(:en) { post.title_before_type_cast.should == 'title' }
      with_locale(:de) { post.title_before_type_cast.should == 'Titel' }
    end
  end

  it "saves all translations on an sti model after locale switching" do
    child = Child.new(:content => 'foo')
    with_locale(:de) { child.content = 'bar' }
    with_locale(:he) { child.content = 'baz' }
    child.save
    child.reload
    child.should be_translated(:en).for(:content).as('foo')
    child.should be_translated(:de).for(:content).as('bar')
    child.should be_translated(:he).for(:content).as('baz')
  end

  describe "attribute reader" do
    it "will use the current locale on Mongoid::Globalize or I18n without arguments" do
      with_locale(:de){ Post.create!(:title => 'Titel', :content => 'Inhalt') }
      I18n.locale = :de
      Post.first.title.should == 'Titel'
      I18n.locale = :en
      Mongoid::Globalize.locale = :de
      Post.first.title.should == 'Titel'
    end

    it "will use the given locale when passed a locale" do
      post = with_locale(:de){ Post.create!(:title => 'Titel', :content => 'Inhalt') }
      post.title(:de).should == 'Titel'
    end
  end

  describe "modifying a translated attribute" do
    it "does not change the untranslated value" do
      post = Post.create(:title => 'title')
      before = post.untranslated_attributes['title']
      post.title = 'changed title'
      post.untranslated_attributes['title'].should == before
    end
  end
end
