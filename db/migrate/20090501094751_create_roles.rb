# Модель Роль
# Позволяет организовать базовый функционал распеределния по ролям
class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table :roles do |t|
      t.string    :name         # Английское имя роли
      t.string    :title        # Название Роли
      t.text      :description  # Текстовое описание Роли
      t.text      :settings     # Настройки Роли
      
      t.timestamps
    end
  end

  def self.down
    drop_table :roles
  end
end