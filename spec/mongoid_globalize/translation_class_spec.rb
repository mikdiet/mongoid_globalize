require 'spec_helper'

describe "Translation class" do
  it "returns by translation_class" do
    Post.translation_class.should == Post::Translation
  end

  it "nested in the model class" do
    Post.const_defined?(:Translation).should be_true
  end

  it "defines embeded_in relation" do
    Post::Translation.should be_embedded_in(:post)
  end

  it "defines a reader for :locale that returns a symbol" do
    post = Post::Translation.new
    post.send(:write_attribute, 'locale', 'de')
    post.locale.should == :de
  end

  it "defines a writer for :locale that writes a string" do
    post = Post::Translation.new
    post.locale = :de
    post.read_attribute('locale').should == 'de'
  end

  it "creates for a namespaced model" do
    lambda do
      module Foo
        module Bar
          class Baz
            include Mongoid::Document
            include Mongoid::Globalize
            translates{ field :bumm }
          end
        end
      end
    end.should_not raise_error
  end

  it "does not override existing translation class" do
    PostTranslation.new.should respond_to(:existing_method)
  end

  describe  "required_attributes" do
    it "returns required attributes (i.e. validates_presence_of)" do
      User.required_attributes.should == [:name, :email]
    end
  end

  describe  "required_translated_attributes" do
    it "does not include non-translated attributes" do
      User.required_translated_attributes.should == [:name]
    end
  end
end
