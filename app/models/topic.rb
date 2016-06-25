class Topic < ActiveRecord::Base
  validates_presence_of :title

  has_many :comments, :dependent => :destroy
  belongs_to :user

  has_many :topic_category_relationships
  has_many :categories, :through => :topic_category_relationships

  has_many :user_topic_favorites
  has_many :users, :through => :user_topic_favorites
  # TODO 3
  # Rename method and find users through this relationship

  def has_comment?
    # TODO 2
    # Implement this method
  end
end
