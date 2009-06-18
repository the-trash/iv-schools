class CreateTimeBorderedPersonalPolicies < ActiveRecord::Migration
  def self.up
    create_table :time_bordered_personal_policies do |t|
      t.integer     :user_id
      t.integer     :role_id
      t.string      :complex_name
      t.datetime    :start_at
      t.datetime    :finish_at
     
      t.timestamps
    end
  end

  def self.down
    drop_table :time_bordered_personal_policies
  end
end
