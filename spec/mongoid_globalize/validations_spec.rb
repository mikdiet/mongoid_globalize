# encoding: utf-8
require 'spec_helper'

describe "Validations" do
  describe "update_attribute" do
    it "succeeds with valid values" do
      post = Post.create(:title => 'foo')
      post.update_attributes(:title => 'baz')
      post.should be_valid
      Post.first.title.should == 'baz'
    end

    it "fails with invalid values" do
      post = Post.create(:title => 'foo')
      post.update_attributes(:title => '').should be_false
      post.should_not be_valid
      post.reload.attributes['title'].should_not be_nil
      post.title.should == 'foo'
    end
  end

  after :each do
    Validatee.reset_callbacks(:validate)
  end

  describe "validates_presence_of" do
    it "works" do
      Validatee.class_eval{ validates_presence_of :string }
      Validatee.new.should_not be_valid
      Validatee.new(:string => 'foo').should be_valid
    end
  end

  describe "validates_confirmation_of" do
    it "works" do
      Validatee.class_eval{ validates_confirmation_of :string }
      Validatee.new(:string => 'foo', :string_confirmation => 'bar').should_not be_valid
      Validatee.new(:string => 'foo', :string_confirmation => 'foo').should be_valid
    end
  end

  describe "validates_acceptance_of" do
    it "works" do
      Validatee.class_eval{ validates_acceptance_of :string, :accept => '1' }
      Validatee.new(:string => '0').should_not be_valid
      Validatee.new(:string => '1').should be_valid
    end
  end

  describe "validates_length_of (:is)" do
    it "works" do
      Validatee.class_eval{ validates_length_of :string, :is => 1 }
      Validatee.new(:string => 'aa').should_not be_valid
      Validatee.new(:string => 'a').should be_valid
    end
  end

  describe "validates_format_of" do
    it "works" do
      Validatee.class_eval{ validates_format_of :string, :with => /^\d+$/ }
      Validatee.new(:string => 'a').should_not be_valid
      Validatee.new(:string => '1').should be_valid
    end
  end

  describe "validates_inclusion_of" do
    it "works" do
      Validatee.class_eval{ validates_inclusion_of :string, :in => %(a) }
      Validatee.new(:string => 'b').should_not be_valid
      Validatee.new(:string => 'a').should be_valid
    end
  end

  describe "validates_exclusion_of" do
    it "works" do
      Validatee.class_eval{ validates_exclusion_of :string, :in => %(b) }
      Validatee.new(:string => 'b').should_not be_valid
      Validatee.new(:string => 'a').should be_valid
    end
  end

  describe "validates_numericality_of" do
    it "works" do
      Validatee.class_eval{ validates_numericality_of :string }
      Validatee.new(:string => 'a').should_not be_valid
      Validatee.new(:string => '1').should be_valid
    end
  end

  pending "validates_uniqueness_of"
  pending "validates_associated"
  pending "a record with valid values on non-default locale validates"
end
