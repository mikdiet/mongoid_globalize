class Post
  include Mongoid::Document
  include Mongoid::Globalize
  belongs_to :blog
  translates do
    field :title
    field :content
    field :published, type: Boolean
    field :published_at, type: DateTime
  end
  validates_presence_of :title
  scope :with_some_title, :conditions => { :title => 'some_title' }
end

class PostTranslation
  include Mongoid::Document
  field :locale
  field :title
  field :content
  field :published, type: Boolean
  field :published_at, type: DateTime
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
  translates{ field :string }
end

class Parent
  include Mongoid::Document
  include Mongoid::Globalize
  translates do
    field :content
    field :type
  end
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
  translates do
    field :content
    field :title
  end
end

class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Globalize
  translates{ field :name }
  field :email
  validates_presence_of :name, :email
end

class Task
  include Mongoid::Document
  include Mongoid::Globalize
  translates do
    fallbacks_for_empty_translations!
    field :name
  end
end
