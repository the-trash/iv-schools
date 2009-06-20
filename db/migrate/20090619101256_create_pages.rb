class CreatePages < ActiveRecord::Migration
  def self.up
    create_table :pages do |t|
      t.integer :user_id # Владелец страницы

      t.string :author      # Автор страницы
      t.string :keywords    # Ключевые слова страницы
      t.string :description # Описание страницы
      t.string :copyright   # Авторское право

      t.string :title         # Заголовок страницы
      t.text   :annotation    # Аннотация (от лат. annotatio — замечание) — краткая характеристика издания: рукописи, статьи или книги.
      t.text   :content       # Содержимое страницы

      # Поведение дерева (вложенные массивы - nested sets)
      t.integer :parent_id
      t.integer :lft
      t.integer :rgt

      t.text    :setting    # Набор различных настроек :: сериализованные данные :: YAML :: должен быть организован единый интерфейс
      
      t.timestamps
    end
  end

  def self.down
    drop_table :pages
  end
end
