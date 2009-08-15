class StorageSection < ActiveRecord::Base
  belongs_to :user
  has_many :storage_files
end
