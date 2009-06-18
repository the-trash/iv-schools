class CreateCountBorderedPersonalPolicies < ActiveRecord::Migration
  def self.up
    create_table :count_bordered_personal_policies do |t|
      t.integer     :user_id
      t.integer     :role_id
      t.string      :complex_name
      t.integer     :counter
      t.integer     :max_count
      
      t.timestamps
    end
  end

  def self.down
    drop_table :count_bordered_personal_policies
  end
end
