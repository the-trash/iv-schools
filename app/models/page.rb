class Page < ActiveRecord::Base
  # Действуй как дерево, привязанное к владельцу (пользователю)
  acts_as_nested_set :scope=>:user
  belongs_to :user
end
