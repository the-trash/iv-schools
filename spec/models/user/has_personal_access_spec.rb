require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe '15:13 18.07.2009' do  

    before(:each) do
      # Админ с базовыми правами роли
      @page_manager_role= Factory.create(:page_manager_role)
      @admin= Factory.create(:admin, :role_id=>@page_manager_role.id)
    end
    
    def create_personal_policies
      # Создать 2 персональных политики для данного пользователя
      @page_manager_policy= Factory.create(:page_manager_personal_policy, :user_id=>@admin.id)
      @page_tree_policy= Factory.create(:page_tree_personal_policy,       :user_id=>@admin.id)
    end
    
    # Отработать функцию has_personal_access?(:section, :action)
    it '9:17 15.07.2009' do
      create_personal_policies
      @admin.has_personal_access?(:pages, :manager).should  be_true
      # Таких прав не существует - вернуть false
      @admin.has_personal_access?(:pages0, :tree).should    be_false
      @admin.has_personal_access?(:pages, :duck).should     be_false
    end#9:17 15.07.2009
    
    # У пользователя нет ни одной персональной политики
    it '14:29 16.07.2009' do
      @admin.role_policies_hash.should      be_instance_of(Hash)
      @admin.personal_policies_hash.should  be_instance_of(Hash)
      @admin.personal_policies_hash.should  be_empty
      # Таких прав не существует - вернуть false
      @admin.has_personal_access?(:pages, :manager).should  be_false
      @admin.has_personal_access?(:pages0, :tree).should    be_false
      @admin.has_personal_access?(:pages, :duck).should     be_false
    end#14:29 16.07.2009
    
    # Установлено превышенное ограничение по кол-ву раз доступа
    # Доступ должен вернуть false
    it '11:48 15.07.2009' do
      create_personal_policies
      @page_manager_policy.update_attributes(:counter=>15, :max_count=>14)
      @admin.has_personal_access?(:pages, :manager).should be_false
    end#11:48 15.07.2009
    
    # Срок прав истеr одну минуту назад
    # Доступ должен вернуть false
    it '11:48 15.07.2009' do
      create_personal_policies
      @page_manager_policy.update_attributes({:start_at=>DateTime.now-3.days, :finish_at=>DateTime.now-1.minute})
      @admin.has_personal_access?(:pages, :manager).should be_false
    end#11:48 15.07.2009

    # Проверить корректность возвращения результата проверки на доступ
    # Различные форматы значений, которые могут хранится в БД
    it '13:34 15.07.2009' do
      create_personal_policies
      # По умолчанию
      @admin.has_personal_access?(:pages, :tree, :recalculate=> true).should    be_true
      @admin.has_personal_access?(:pages, :manager, :recalculate=> true).should be_true
      # Проверка функции пересчета
      @page_manager_policy.update_attribute(:value, false)
      @admin.has_personal_access?(:pages, :manager).should                      be_true
      @admin.has_personal_access?(:pages, :manager, :recalculate=> true).should be_false
      # Проверка функции пересчета
      @page_manager_policy.update_attribute(:value, true)
      @admin.has_personal_access?(:pages, :manager).should be_false
      @admin.has_personal_access?(:pages, :manager, :recalculate=> true).should be_true
    end#13:34 15.07.2009
    
end
