class ChangePageDisplayField < ActiveRecord::Migration
  def self.up
    rename_column :pages, :display, :display_state
  end

  def self.down
    rename_column :pages, :display_state, :display
  end
end
