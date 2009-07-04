class Role < ActiveRecord::Base
  # Заголовок не должен быть пустым
  # Описание должно быть более 30 символов
  has_many :users
end
