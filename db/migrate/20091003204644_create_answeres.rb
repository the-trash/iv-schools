class CreateAnsweres < ActiveRecord::Migration
  def self.up
    create_table :answeres do |t|
      t.string :from
      t.string :email
      t.string :to
      t.string :topic
      t.text :question
      t.text :answere
      t.integer :user_id, :default=>NIL

      t.timestamps
    end
  end

  def self.down
    drop_table :answeres
  end
end
