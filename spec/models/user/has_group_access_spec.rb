require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe '15:18 18.07.2009' do
  # Исполняется перед каждым тестом раздела
  before(:each) do
    # Админ с базовыми правами роли
    @page_manager_role= Factory.create(:page_manager_role)
    @admin= Factory.create(:admin, :role_id=>@page_manager_role.id)
  end

  def create_group_policies
    # Создать 2 групповых политики для данного пользователя(роли)
    @page_manager_gpolicy=  Factory.create(:page_manager_group_policy,  :role_id=>@page_manager_role.id)
    @page_tree_gpolicy=     Factory.create(:page_tree_group_policy,     :role_id=>@page_manager_role.id)
  end
  
  # Проверить корректность возвращения результата проверки на доступ
  # Различные форматы значений, которые могут хранится в БД
  it '13:34 15.07.2009' do
    create_group_policies
    #true
    @admin.has_group_access?(:pages, :manager, :recalculate=> true).should be_true
    #false
    @page_manager_gpolicy.update_attribute(:value, false)
    @admin.has_group_access?(:pages, :manager, :recalculate=> true).should be_false
    # обновлено, но не установлен флаг пересчета - должно сохранятся предыдущее значение
    @page_manager_gpolicy.update_attribute(:value, true)
    @admin.has_group_access?(:pages, :manager).should be_false
    # ничего не обнавляем, но просим пересчитать хеш доступа согласно данных в БД
    @admin.has_group_access?(:pages, :manager, :recalculate=> true).should be_true
  end#13:34 15.07.2009
end
