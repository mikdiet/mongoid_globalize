# encoding: utf-8
require 'spec_helper'

describe "Dirty tracking" do
  it "works" do
    post = Post.create(:title => 'title', :content => 'content')
    post.changed.should == []

    post.title = 'title'
    post.changed.should == []

    post.title = 'changed title'
    post.changed.should == ['title']

    post.content = 'changed content'
    post.changed.should include('title', 'content')
  end

  it 'works per a locale' do
    post = Post.create(:title => 'title', :content => 'content')
    post.changed.should == []

    post.title = 'changed title'
    post.changes.should == { 'title' => ['title', 'changed title'] }
    post.save

    I18n.locale = :de
    post.title = 'Alt Titel'

    post.title = 'Titel'
    post.changes.should == { 'title' => [nil, 'Titel'] }
  end

  it 'works after locale switching' do
    post = Post.create(:title => 'title', :content => 'content')
    post.changed.should == []

    post.title = 'changed title'
    I18n.locale = :de
    post.changed.should == ['title']
  end

  it 'works on sti model' do
    child = Child.create(:content => 'foo')
    child.changed.should == []

    child.content = 'bar'
    child.changed.should == ['content']

    child.content = 'baz'
    child.changed.should include('content')
  end

  it 'works on sti model after locale switching' do
    child = Child.create(:content => 'foo')
    child.changed.should == []

    child.content = 'bar'
    I18n.locale = :de
    child.changed.should == ['content']
  end
end
