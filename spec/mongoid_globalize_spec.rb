# encoding: utf-8
require 'spec_helper'

describe Mongoid::Globalize do
  describe "a translated record" do
    it "has many embed translations" do
      Post.should embed_many(:translations)
    end
  end

  describe "#translations" do
    # It's different of G3. In G3 @translations are empty for this situation
    its "have one empty with current locale for a new record" do
      translations = Post.new.translations
      translations.should == [translations.first]
      translations.first.locale.should == :en
    end
  end

  describe "#create" do
    it "uses the given locale" do
      post = Post.create(:title => 'Titel', :locale => :de)
      post.should be_translated(:de).for(:title).as('Titel')
    end
  end

  it "can translate boolean values" do
    post = Post.create(:title => 'Titel', :published => true, :locale => :de)
    post.should be_translated(:de).for(:published).as(true)
  end

  it "can translate datetime values" do
    now = Time.now
    post = Post.create(:title => 'Titel', :published_at => now, :locale => :de)
    post.should be_translated(:de).for(:published_at).as(now)
  end

  describe "#attributes=" do
    it "uses the given locale" do
      post = Post.create(:title => 'title')
      post.attributes = { :title => 'Titel', :locale => :de }
      post.save
      post.reload
      post.translations.size.should == 2
      post.should be_translated(:de).for(:title).as('Titel')
      post.should be_translated(:en).for(:title).as('title')
    end
  end

  describe "#create on associations" do
    it "works" do
      blog = Blog.create
      blog.posts.create(:title => 'title')
      blog.posts.create(:title => 'Titel', :locale => :de)
      blog.posts.size.should == 2
      blog.posts.first.should be_translated(:en).for(:title).as('title')
      blog.posts.last.should be_translated(:de).for(:title).as('Titel')
    end
  end

  describe "named scopes" do
    its "work" do
      post = Blog.create.posts.create(:title => 'some title')
      post.reload
      post.should be_translated(:en).for(:title).as('some title')
    end
  end

  it "saves a translations document for each locale using a given locale" do
    post = Post.create(:title => 'Titel', :locale => :de)
    post.update_attributes(:title => 'title', :locale => :en)
    post.translations.size.should == 2
    post.should be_translated(:de).for(:title).as('Titel')
    post.should be_translated(:en).for(:title).as('title')
  end

  it "saves a translations document for each locale using the current I18n locale" do
    post = with_locale(:de) { Post.create(:title => 'Titel') }
    with_locale(:en) { post.update_attributes(:title => 'title') }
    post.translations.size.should == 2
    post.should be_translated(:en).for(:title).as('title')
    post.should be_translated(:de).for(:title).as('Titel')
  end

  describe "#reload" do
    it "works with translated attributes" do
      post = Post.create(:title => 'foo')
      post.title = 'baz'
      post.reload
      post.title.should == 'foo'
    end

    it "accepts no options" do  # because Mongoid's #reload doesn't accept ones
      post = Post.create(:title => "title")
      lambda{ post.reload(:readonly => true) }.should raise_error(ArgumentError)
    end
  end

  describe "#destroy" do
    it "destroys dependent translations" do
      # it's true due to translations are embedded into document
    end
  end

  describe "#to_xml" do
    it "includes translated fields" do
      post = Post.create(:title => "foo", :content => "bar")
      post.reload
      post.to_xml.should match(%r(<title>foo</title>))
      post.to_xml.should match(%r(<content>bar</content>))
    end

    it " doesn't affect untranslated models" do
      blog = Blog.create(:description => "my blog")
      blog.reload
      blog.to_xml.should match(%r(<description>my blog</description>))
    end
  end

  describe "#translated_locales" do
    it "returns locales that have translations" do
      first = Post.create!(:title => 'title', :locale => :en)
      first.update_attributes(:title => 'Title', :locale => :de)
      second = Post.create!(:title => 'title', :locale => :en)
      second.update_attributes(:title => 'titre', :locale => :fr)
      Post.translated_locales.should == [:de, :en, :fr]
      first.translated_locales.should == [:de, :en]
      second.translated_locales.should == [:en, :fr]

      first.reload
      second.reload
      first.translated_locales.should == [:de, :en]
      second.translated_locales.should == [:en, :fr]
    end
  end

  describe "a model with an after_save callback that reloads the model" do
    it "still saves correctly" do
      reloading_post = ReloadingPost.create!(:title => 'title')
      reloading_post.title.should == 'title'
      reloading_post.should be_translated(:en).for(:title).as('title')
    end
  end

  describe "#with_translations" do
    it "loads only documents with translations" do
      Post.create(:title => 'title 1')
      Post.create(:title => 'title 2')
      Post.with_translations.map(&:title).sort.should == ['title 1', 'title 2']
      Post.with_translations(:de).should == []
    end

    it "doesn't load document with present locale, but absent required attributes" do
      post = Post.create(:title => 'title 1')
      post.set_translations(
        :en => { :title => 'updated title' },
        :ru => { :content => 'без заголовка' }
      )
      Post.with_translations(:en).first.should == post
      Post.with_translations(:ru).first.should == nil
    end
  end

  describe "a subclass of an untranslated model" do
    it "can translate attributes" do
      post = Post.create(:title => 'title')
      translated_comment = TranslatedComment.create(:post => post, :content => 'content')
      lambda{ translated_comment.translations }.should_not raise_error
      translated_comment.should be_translated(:en).for(:content).as('content')
    end

    it "works when modifiying translated attributes" do
      post = Post.create(:title => 'title')
      translated_comment = TranslatedComment.create(:post => post, :content => 'content')
      translated_comment.update_attributes(:content => 'Inhalt',
                                           :locale => :de).should be_true
      translated_comment.should be_translated(:en).for(:content).as('content')
      translated_comment.should be_translated(:de).for(:content).as('Inhalt')
    end
  end

  describe "#delete" do
    it "works" do
      task = Task.create(:title => 'title')
      task.reload
      task.delete.should be_true
      Task.count.should be_zero
    end
  end
end
