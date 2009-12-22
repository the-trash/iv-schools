class CreateReports < ActiveRecord::Migration
  def self.up
    create_table :reports do |t|
      t.integer :user_id
      t.string :zip
      
      t.string :title
      t.text :description
      t.text :content
      t.text :prepared_content
      
      t.string :display_state, :default => 'show'
      t.text :settings
      
      t.integer :parent_id
      t.integer :lft
      t.integer :rgt

      t.timestamps
    end
  end

  def self.down
    drop_table :reports
  end
end
