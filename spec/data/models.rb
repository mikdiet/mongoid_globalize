class Post
  include Mongoid::Document
  include Mongoid::Globalize
  belongs_to :blog
  translates :title, :content

  translates :published => Boolean
  translates :published_at => DateTime
  validates_presence_of :title
  scope :with_some_title, :conditions => { :title => 'some_title' }
end

class PostTranslation
  include Mongoid::Document
  field :locale
  field :title
  field :content
  field :published => Boolean
  field :published_at => DateTime
  embedded_in :post

  def existing_method
  end
end

class ReloadingPost < Post
  after_create { reload }
end

class Blog
  include Mongoid::Document
  has_many :posts
  field :name
end

class Validatee
  include Mongoid::Document
  include Mongoid::Globalize
  translates :string
end

class Parent
  include Mongoid::Document
  include Mongoid::Globalize
  translates :content, :type
end

class Child < Parent
end

class Comment
  include Mongoid::Document
  field :content
  validates_presence_of :content
  belongs_to :post
end

class TranslatedComment < Comment
  include Mongoid::Globalize
  translates :content, :title
end

class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Globalize
  translates :name
  field :email
  validates_presence_of :name, :email
end

class Task
  include Mongoid::Document
  include Mongoid::Globalize
  fallbacks_for_empty_translations!
  translates :name
end
