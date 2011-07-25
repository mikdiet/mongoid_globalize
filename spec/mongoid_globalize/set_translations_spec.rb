# encoding: utf-8
require 'spec_helper'

describe "#set_translations" do
  it "sets multiple translations at once" do
    post = Post.create(:title => 'title', :content => 'content', :locale => :en)
    post.update_attributes(:title => 'Titel', :content => 'Inhalt', :locale => :de)
    post.set_translations(
      :en => { :title => 'updated title', :content => 'updated content' },
      :de => { :title => 'geänderter Titel', :content => 'geänderter Inhalt' }
    )
    post.reload
    post.should be_translated(:en).for([:title, :content])
                .as(['updated title', 'updated content'])
    post.should be_translated(:de).for([:title, :content])
                .as(['geänderter Titel', 'geänderter Inhalt'])
  end

  it "does not touch existing translations for other locales" do
    post = Post.create(:title => 'title', :content => 'content', :locale => :en)
    post.update_attributes(:title => 'Titel', :content => 'Inhalt', :locale => :de)
    post.set_translations(:en => { :title => 'updated title', :content => 'updated content' })
    post.reload
    post.should be_translated(:en).for([:title, :content])
                .as(['updated title', 'updated content'])
    post.should be_translated(:de).for([:title, :content]).as(['Titel', 'Inhalt'])
  end

  it "does not touch existing translations for other attributes" do
    post = Post.create(:title => 'title', :content => 'content', :locale => :en)
    post.update_attributes(:title => 'Titel', :content => 'Inhalt', :locale => :de)
    post.set_translations(
      :en => { :title => "updated title" },
      :de => { :content => "geänderter Inhalt" }
    )
    post.reload
    post.should be_translated(:en).for([:title, :content]).as(['updated title', 'content'])
    post.should be_translated(:de).for([:title, :content]).as(['Titel', 'geänderter Inhalt'])
  end

  # in G3 error raises here. But Mongo it support, so why not.. :)
  it "sets unknown attributes" do
    post = Post.create(:title => 'title', :content => 'content', :locale => :en)
    post.update_attributes(:title => 'Titel', :content => 'Inhalt', :locale => :de)
    post.set_translations :de => {:does_not_exist => 'not exist'}
    post.reload
    post.translation_for(:de).does_not_exist.should == 'not exist'
  end
end
