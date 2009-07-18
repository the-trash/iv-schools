require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe '15:21 18.07.2009' do  
    def create_users
      @admin= Factory.create(:admin)
      @ivanov= Factory.create(:ivanov)
      @petrov= Factory.create(:petrov)
    end

    def admin_has_ivanov_as_resource
      @resource_ivanov=Factory.create(:page_manager_personal_resource_policy, :user_id=>@admin.id)
      @resource_ivanov.resource= @ivanov
      @resource_ivanov.save
    end    
    
    # Создать пользователю персональные политики к различным объектам
    it '13:05 17.07.2009' do
      create_users

      # У пользователя еще нет ни одного персонального права - должно вернуть false
      @admin.has_personal_resource_access_for?(@ivanov, :profile, :edit).should be_false
            
      # Пользователь обладает персональной политикой к ресурсу пользователь
      personal_resource_policy0= Factory.create(:profile_edit_personal_resource_policy,
        :user_id=>@admin.id  
      )
      personal_resource_policy0.resource= @ivanov
      personal_resource_policy0.save
      # Пользователь обладает персональной политикой к ресурсу пользователь
      personal_resource_policy1= Factory.create(:profile_edit_personal_resource_policy,
        :user_id=>@admin.id  
      )
      # установить подчиненный объект
      personal_resource_policy1.resource= @petrov
      personal_resource_policy1.save
      # Проверка на синтаксические ошибки в функции
      @admin.has_personal_resource_access_for?(@ivanov, :profile, :edit, :recalculate=>true).should be_true
    end# 13:05 17.07.2009    
end
