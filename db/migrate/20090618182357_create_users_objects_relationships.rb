class CreateUsersObjectsRelationships < ActiveRecord::Migration
  def self.up
    create_table :users_objects_relationships do |t|
      t.integer     :user_id
      t.integer :object_id
      t.string  :object_type
      
      t.string      :complex_name
      t.string      :value
      
      t.integer     :counter
      t.integer     :max_count
      
      t.datetime    :start_at
      t.datetime    :finish_at
  
      t.timestamps
    end
  end

  def self.down
    drop_table :users_objects_relationships
  end
end
