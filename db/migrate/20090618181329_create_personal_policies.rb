class CreatePersonalPolicies < ActiveRecord::Migration
  def self.up
    create_table :personal_policies do |t|
      t.integer   :user_id
      t.integer   :role_id
      t.string    :complex_name
      t.string    :value
  
      t.timestamps
    end
  end

  def self.down
    drop_table :personal_policies
  end
end
