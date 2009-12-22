class ChangeDisplayFieldOfPage < ActiveRecord::Migration
  def self.up
    rename_column :pages,   :display_state, :state
    rename_column :reports, :display_state, :state
  end
end
