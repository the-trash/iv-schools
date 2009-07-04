class Profile < ActiveRecord::Base
# Профайл пользователя (Анкета пользователя)
  has_one :user
end
