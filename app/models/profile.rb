class Profile < ActiveRecord::Base
# Профайл пользователя (Анкета пользователя)
  belongs_to :user
end
