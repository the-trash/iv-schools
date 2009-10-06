class CreateUuestions < ActiveRecord::Migration
  def self.up
    create_table :questions do |t|
      t.string :from
      t.string :email
      t.string :website
      
      t.string :to
      t.string :topic
      t.text :question
      t.text :answere
      t.integer :user_id, :default=>NIL

      t.timestamps
    end
  end

  def self.down
    drop_table :questions
  end
end
