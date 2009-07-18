require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe '15:17 18.07.2009' do  

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
    
    # Проверить корректность возвращения результата проверки на блокировку доступа
    # Различные форматы значений, которые могут хранится в БД
    it '12:48 16.07.2009' do
      create_group_policies      
      # блокировка актуальна
        @page_manager_gpolicy.update_attribute(:value, false)
        @admin.has_group_block?(:pages, :manager, :recalculate=> true).should be_true
      # Различные значения блокирующей политики
        @page_manager_gpolicy.update_attribute(:value, false)
        @admin.has_group_block?(:pages, :manager, :recalculate=> true).should be_true
      # Актуально - но значения не подподают под разряд false
        @page_manager_gpolicy.update_attribute(:value, true)
        @admin.has_group_block?(:pages, :manager, :recalculate=> true).should be_false
      # Вернуть значение блокировки
        @page_manager_gpolicy.update_attribute(:value, false)
        @admin.has_group_block?(:pages, :manager, :recalculate=> true).should be_true
      # Актуальность
      # Кол-во: актуально, Время: актуально
        @page_manager_gpolicy.update_attributes({:counter=>10, :max_count=>10})
        @admin.has_group_block?(:pages, :manager, :recalculate=> true).should be_true
      # Кол-во: не актуально, Время: актуально
        @page_manager_gpolicy.update_attributes({:counter=>10, :max_count=>9})
        @admin.has_group_block?(:pages, :manager, :recalculate=> true).should be_false
      # Кол-во: актуально, Время: не актуально
        @page_manager_gpolicy.update_attributes({:counter=>10, :max_count=>10, :start_at=>1.day.ago, :finish_at=>1.second.ago})
        @admin.has_group_block?(:pages, :manager, :recalculate=> true).should be_false
      # Кол-во: не актуально, Время: не актуально
        @page_manager_gpolicy.update_attributes({:counter=>10, :max_count=>9, :start_at=>1.day.ago, :finish_at=>1.second.ago})
        @admin.has_group_block?(:pages, :manager, :recalculate=> true).should be_false
      # Снова Кол-во: актуально, Время: актуально
        @page_manager_gpolicy.update_attributes({:counter=>10, :max_count=>11, :start_at=>1.day.ago, :finish_at=>1.day.from_now})
        @admin.has_group_block?(:pages, :manager, :recalculate=> true).should be_true
    end#12:48 16.07.2009
    
end
