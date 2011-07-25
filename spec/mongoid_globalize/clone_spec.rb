# encoding: utf-8
require 'spec_helper'

describe "Clone" do
  it 'stores translations from clonned new record' do
    check_stored_translations(standard_post.clone)
  end

  it 'stores translations from clonned created record' do
    clonned = saved_post.clone
    check_stored_translations(clonned)
  end

  it 'stores translations from clonned found record' do
    check_stored_translations( Post.find(saved_post.id).clone )
  end

  it 'stores translations from clonned reloaded after creation record' do
    check_stored_translations(saved_post.reload.clone)
  end
end

def standard_post
  post = Post.new({:title => 'title', :content => 'content'})
  with_locale(:he) { post.title= 'שם' }
  post
end

def saved_post
  standard_post.tap{|p| p.save!}
end

def translations_modifications(clonned)
  clonned.content = 'another content'
  with_locale(:de) { clonned.title = 'Titel' }
end

def translations_specs(clonned)
  clonned.should be_translated(:en).for(:title).as('title')             # original
  clonned.should be_translated(:en).for(:content).as('another content') # changed
  clonned.should be_translated(:de).for(:title).as('Titel')             # new
  clonned.should be_translated(:he).for(:title).as('שם')                # untouched language
end

def check_stored_translations(clonned)
  translations_modifications(clonned)
  translations_specs(clonned)
  clonned.save!
  clonned.reload
  translations_specs(clonned)
end
