require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User do

  # Исполняется однажды перед всеми тестами
  # Установить пример валидных и не валидных данных
  before(:all) do  
    @valid_attributes = {
      :login=>'admin123',
      :email=>'admin@admin.ru',
      :password=>'admin@admin.ru',
      :password_confirmation=>'admin@admin.ru',
      :name=>'Привет!'
    }
    
    @invalid_attributes = {
      :login=>'',
      :email=>'secondadmin@admin.ru',
      :password=>'admin@admin.ru',
      :password_confirmation=>'admin@admin.ru',
      :name=>'Привет!2'
    }
  end

  # Исполняется перед каждым тестом
  before(:each) do
  end

  # Создание пользователя
  it "user create" do
    User.create!(@valid_attributes)
  end
  
  # Ошибка при пустом логине
  it "login incorrect" do
    u= User.new @invalid_attributes
    u.should have(2).error_on(:login)
  end
  
  # Пользователь должен быть уникальным
  it "user must be uniq" do
    u1= User.new @valid_attributes
    u1.save
    
    u2= User.new @valid_attributes
    u2.save.should be_false
  end
  
  it '17:40 14.07.2009, Должен иметь роль и политику доступа к просмотру pages[:tree]' do
    page_manager_role= Factory.create(:page_manager_role)
    admin_user= Factory.create(:admin,
      :role_id=>page_manager_role.id
    )
    # Создать роль
    # Создать пользователя с данной ролью
    # Должен быть хеш политик из стандартной роли
    admin_user.role_policies_hash.should be_instance_of(Hash)
    # Должно быть два правила доступа
    # Обратимся и через строку и через символ
    admin_user.has_role_policy?('pages', 'tree').should be_true
    admin_user.has_role_policy?(:pages, :manager).should be_true
    # Этого правила быть не должно
    admin_user.has_role_policy?(:pages, :some_stupid_policy).should be_false
  end#17:40 14.07.2009

###################################################################################################
# Тестирование общих функций системы политик
###################################################################################################

  describe 'CommonPolicyFunctuions' do
  
    # get_policy_hash => Функция формирования хешей политик для различных уровней правовой системы
    it '23:34 16.07.2009' do
      admin_user= Factory.create(:admin)
      # Пустые параметры - должна вернуть Hesh
      admin_user.get_policy_hash.should be_instance_of(Hash)
    end# 23:34 16.07.2009
    
    # Проверка реакции функции проверки политик для группы/пользователя на отсутствие
    # временных || колличественных границ использования права
    it '23:40 16.07.2009' do
      # Создать пользователя
      admin_user= Factory.create(:admin)
      # 'personal_policies_hash'=>'personal',
      # 'group_policies_hash'=>'group'
      hesh_fn= 'personal_policies_hash'
      factory_name= 'personal'
      # Создать не ограниченную политику указанного уровня с указанным именем фабрики
      Factory.create("page_tree_#{factory_name}_policy_unlimited",
        :user_id=>admin_user.id
      )
      # Создать не ограниченную политику указанного уровня с указанным именем фабрики
      Factory.create("page_manager_#{factory_name}_policy_unlimited",
        :user_id=>admin_user.id
      )
      admin_user.check_access(:pages, :tree, hesh_fn, :recalculate=>true)
      admin_user.check_access(:pages, :manager, hesh_fn, :recalculate=>true)
    end#23:40 16.07.2009
    
    # Работа функции проверки актуальности времени
    it '10:29 17.07.2009' do
      # Пользователь и персональная роль без установленных ограничений
      admin_user= Factory.create(:admin)
      policy= Factory.create(:page_tree_personal_policy_unlimited,
        :user_id=>admin_user.id
      )
      # Нет ограничений по времени
      admin_user.policy_actual_by_time?(policy.start_at, policy.finish_at).should be_true

      # Верхняя граница
        # Действительная
        policy.update_attribute(:finish_at, DateTime.now+1.minute)
        admin_user.policy_actual_by_time?(policy.start_at, policy.finish_at).should be_true
        # Не действительная
        policy.update_attribute(:finish_at, DateTime.now-1.minute)
        admin_user.policy_actual_by_time?(policy.start_at, policy.finish_at).should be_false
      
      # В исходную
      policy.update_attributes(:start_at=>nil, :finish_at=>nil)
      
      # Нижняя граница
        # Действительная
        policy.update_attribute(:start_at, DateTime.now-1.minute)
        admin_user.policy_actual_by_time?(policy.start_at, policy.finish_at).should be_true
        # Не действительная
        policy.update_attribute(:start_at, DateTime.now+1.minute)
        admin_user.policy_actual_by_time?(policy.start_at, policy.finish_at).should be_false
        
      # Действительный интервал
      policy.update_attributes(:start_at=>DateTime.now-1.minute, :finish_at=>DateTime.now+1.minute)
      admin_user.policy_actual_by_time?(policy.start_at, policy.finish_at).should be_true
      # Еще не начался
      policy.update_attributes(:start_at=>DateTime.now+1.minute, :finish_at=>DateTime.now+2.minute)
      admin_user.policy_actual_by_time?(policy.start_at, policy.finish_at).should be_false
      # Уже закончился
      policy.update_attributes(:start_at=>DateTime.now-2.minute, :finish_at=>DateTime.now-1.minute)
      admin_user.policy_actual_by_time?(policy.start_at, policy.finish_at).should be_false
      # Ошибочная ситуаця дата окончания меньше даты начала
      policy.update_attributes(:start_at=>DateTime.now+2.minute, :finish_at=>DateTime.now-2.minute)
      admin_user.policy_actual_by_time?(policy.start_at, policy.finish_at).should be_false
      # Ошибочная ситуаця дата окончания меньше даты начала - еще один вариант
      policy.update_attributes(:start_at=>DateTime.now+2.minute, :finish_at=>DateTime.now+1.minute)
      admin_user.policy_actual_by_time?(policy.start_at, policy.finish_at).should be_false
      # Ошибочная ситуаця начало и окончание правила - именно сейчас.
      policy.update_attributes(:start_at=>DateTime.now, :finish_at=>DateTime.now)
    end#10:29 17.07.2009
  end
    
###################################################################################################
# Персональная политика
###################################################################################################

  # Отработка Персональных политик
  describe PersonalPolicy do
    it '9:17 15.07.2009, Отработать функцию has_personal_access?(:section, :action)' do
      # Создать роль и админа с этой ролью
      page_manager_role= Factory.create(:page_manager_role)
      admin_user= Factory.create(:admin,
        :role_id=>page_manager_role.id
      )
      # Создать персональную политику для данного пользователя
      personal_policy= Factory.create(:page_manager_personal_policy,
        :user_id=>admin_user.id
      )
      personal_policy= Factory.create(:page_tree_personal_policy,
        :user_id=>admin_user.id
      )
      admin_user.has_personal_access?(:pages, :manager).should be_true
      # Таких прав не существует - вернуть nil
      admin_user.has_personal_access?(:pages0, :tree).should be_false
      admin_user.has_personal_access?(:pages, :duck).should be_false
    end#9:17 15.07.2009
    
    # У пользователя нет ни одной персональной политики
    it '14:29 16.07.2009' do
      # Создать роль и админа с этой ролью
      page_manager_role= Factory.create(:page_manager_role)
      admin_user= Factory.create(:admin,
        :role_id=>page_manager_role.id
      )
      admin_user.role_policies_hash.should be_instance_of(Hash)
      admin_user.personal_policies_hash.should be_instance_of(Hash)
      admin_user.personal_policies_hash.should be_empty
      # Таких прав не существует - вернуть nil
      admin_user.has_personal_access?(:pages, :manager).should be_false
      admin_user.has_personal_access?(:pages0, :tree).should be_false
      admin_user.has_personal_access?(:pages, :duck).should be_false
    end#14:29 16.07.2009
    
    # Установлено превышенное ограничение по кол-ву раз доступа
    # Доступ должен вернуть false
    it '11:48 15.07.2009' do
      # Создать роль и админа с этой ролью
      page_manager_role= Factory.create(:page_manager_role)
      admin_user= Factory.create(:admin,
        :role_id=>page_manager_role.id
      )
      # Создать персональную политику для данного пользователя
      personal_policy= Factory.create(:page_manager_personal_policy,
        :user_id=>admin_user.id,
        :counter=>16,
        :max_count=>15
      )
      personal_policy= Factory.create(:page_tree_personal_policy,
        :user_id=>admin_user.id
      )
      # p admin_user.personal_policies_hash
      admin_user.has_personal_access?(:pages, :manager).should be_false
    end#11:48 15.07.2009
    
    # Срок прав истеr одну минуту назад
    # Доступ должен вернуть false
    it '11:48 15.07.2009' do
      # Создать роль и админа с этой ролью
      page_manager_role= Factory.create(:page_manager_role)
      admin_user= Factory.create(:admin,
        :role_id=>page_manager_role.id
      )
      # Создать персональную политику для данного пользователя
      personal_policy= Factory.create(:page_manager_personal_policy,
        :user_id=>admin_user.id,
        :start_at=>DateTime.now-3.days,
        :finish_at=>DateTime.now-1.minute
      )
      personal_policy= Factory.create(:page_tree_personal_policy,
        :user_id=>admin_user.id
      )
      admin_user.has_personal_access?(:pages, :manager).should be_false
    end#11:48 15.07.2009
    
  end#PersonalPolicy
  
  describe 'PersonalPolicyOutputData has_personal_access?' do
    # Проверить корректность возвращения результата проверки на доступ
    # Различные форматы значений, которые могут хранится в БД
    it '13:34 15.07.2009' do
      # Создать роль и админа с этой ролью
      page_manager_role= Factory.create(:page_manager_role)
      admin_user= Factory.create(:admin,
        :role_id=>page_manager_role.id
      )
      # Различные варианты ввода данных
      # true
      personal_policy= Factory.create(:page_manager_personal_policy,
        :user_id=>admin_user.id,
        :value=>true
      )
      # Просто так - если у пользователя несколько персональных политик
      Factory.create(:page_tree_personal_policy,
        :user_id=>admin_user.id,
        :value=>true
      )
      #true
      admin_user.has_personal_access?(:pages, :manager, :recalculate=> true).should be_true
      personal_policy.update_attribute(:value, 'true')
      admin_user.has_personal_access?(:pages, :manager, :recalculate=> true).should be_true
      #false
      personal_policy.update_attribute(:value, false)
      admin_user.has_personal_access?(:pages, :manager, :recalculate=> true).should be_false
      
      # обновлено, но не установлен флаг пересчета - должно сохранятся предыдущее значение
      personal_policy.update_attribute(:value, true)
      admin_user.has_personal_access?(:pages, :manager).should be_false
      # ничего не обнавляем, но просим пересчитать хеш доступа согласно данных в БД
      admin_user.has_personal_access?(:pages, :manager, :recalculate=> true).should be_true
    end#13:34 15.07.2009
  end#PersonalPolicyOutputData has_personal_access?
  
  describe 'PersonalPolicyOutputData has_personal_block?' do
    # Проверить корректность возвращения результата проверки на блокировку доступа
    # Различные форматы значений, которые могут хранится в БД
    it '12:48 16.07.2009' do
      # Создать роль и админа с этой ролью
      page_manager_role= Factory.create(:page_manager_role)
      admin_user= Factory.create(:admin,
        :role_id=>page_manager_role.id
      )
      # Создал актуальную персональную политику
      # установил значение
      personal_policy= Factory.create(:page_manager_personal_policy,
        :user_id=>admin_user.id,
        :value=>false
      )
      # Просто так - если у пользователя несколько персональных политик
      Factory.create(:page_tree_personal_policy,
        :user_id=>admin_user.id,
        :value=>true
      )
      # блокировка актуальна
      admin_user.has_personal_block?(:pages, :manager, :recalculate=> true).should be_true
      # Различные значения блокирующей политики
      personal_policy.update_attribute(:value, false)
      admin_user.has_personal_block?(:pages, :manager, :recalculate=> true).should be_true
      # p admin_user.personal_policies_hash
      # Актуально - но значения не подподают под разряд false
      personal_policy.update_attribute(:value, true)
      admin_user.has_personal_block?(:pages, :manager, :recalculate=> true).should be_false
      # Вернуть значение блокировки
      personal_policy.update_attribute(:value, false)
      admin_user.has_personal_block?(:pages, :manager, :recalculate=> true).should be_true
      # Актуальность
      # Кол-во: актуально, Время: актуально
      personal_policy.update_attributes({:counter=>10, :max_count=>10})
      admin_user.has_personal_block?(:pages, :manager, :recalculate=> true).should be_true
      # Кол-во: не актуально, Время: актуально
      personal_policy.update_attributes({:counter=>10, :max_count=>9})
      admin_user.has_personal_block?(:pages, :manager, :recalculate=> true).should be_false
      # Кол-во: актуально, Время: не актуально
      personal_policy.update_attributes({:counter=>10, :max_count=>10, :start_at=>1.day.ago, :finish_at=>1.second.ago})
      admin_user.has_personal_block?(:pages, :manager, :recalculate=> true).should be_false
      # Кол-во: не актуально, Время: не актуально
      personal_policy.update_attributes({:counter=>10, :max_count=>9, :start_at=>1.day.ago, :finish_at=>1.second.ago})
      admin_user.has_personal_block?(:pages, :manager, :recalculate=> true).should be_false
      # Снова Кол-во: актуально, Время: актуально
      personal_policy.update_attributes({:counter=>10, :max_count=>11, :start_at=>1.day.ago, :finish_at=>1.day.from_now})
      admin_user.has_personal_block?(:pages, :manager, :recalculate=> true).should be_true
    end#12:48 16.07.2009
  end#PersonalPolicyOutputData has_personal_block?
  
###################################################################################################
# Групповая политика
###################################################################################################
  describe 'group_policies_hash' do
    # У пользователя нет роли (группы)
    # Значит - невозможно получить групповые политики
    it '14:40 16.07.2009' do
      admin_user= Factory.create(:admin)
      admin_user.group_policies_hash.should be_instance_of(Hash)
      admin_user.group_policies_hash.should be_empty
    end#14:40 16.07.2009
    
    # У пользователя есть роль (группа)
    # Набор политик - пустой
    it '15:54 16.07.2009' do
      # Создать роль и админа с этой ролью
      page_manager_role= Factory.create(:page_manager_role)
      admin_user= Factory.create(:admin,
        :role_id=>page_manager_role.id
      )
      admin_user.group_policies_hash.should be_instance_of(Hash)
      admin_user.group_policies_hash.should be_empty
    end#15:54 16.07.2009
    
    # У пользователя есть роль (группа)
    # Есть одна дополнительная рупповая политика
    it '16:00 16.07.2009' do
      # Создать роль и админа с этой ролью
      page_manager_role= Factory.create(:page_manager_role)
      admin_user= Factory.create(:admin,
        :role_id=>page_manager_role.id
      )      
      # Создадим одну политику
      group_policy= Factory.create(:page_manager_group_policy,
        :role_id=>page_manager_role.id
      )
      # Должна быть одна групповая политика для данной роли
      GroupPolicy.find_all_by_role_id(admin_user.role.id).should have(1).items
      admin_user.group_policies_hash.should be_instance_of(Hash)
      # Должен быть один раздел pages в нем одна запись о политике
      admin_user.group_policies_hash.should have(1).items
      admin_user.group_policies_hash[:pages].should have(1).items
      # Создадим вторую политику
      group_policy2= Factory.create(:page_tree_group_policy,
        :role_id=>page_manager_role.id
      )
      # Должна быть 2 групповых политики для данной роли
      GroupPolicy.find_all_by_role_id(admin_user.role.id).should have(2).items
      admin_user.group_policies_hash.should be_instance_of(Hash)
      # В БД данные изменились, но хеш не пересчитан
      admin_user.group_policies_hash.should have(1).items
      admin_user.group_policies_hash[:pages].should have(1).items
      # Пересчитать хеш и вернуть действительное кол-во групповых политик - т.е. 2
      # Должен быть один раздел pages в нем две записи о политиках
      admin_user.group_policies_hash.should have(1).items
      admin_user.group_policies_hash(:recalculate=>true)[:pages].should have(2).items
    end#16:00 16.07.2009
  end#describe 'group_policies_hash'
  
  describe 'GroupPolicyOutputData has_group_block?' do
    # Проверить корректность возвращения результата проверки на блокировку доступа
    # Различные форматы значений, которые могут хранится в БД
    it '12:48 16.07.2009' do
      # Создать роль и админа с этой ролью
      page_manager_role= Factory.create(:page_manager_role)
      admin_user= Factory.create(:admin,
        :role_id=>page_manager_role.id
      )
      # Создал актуальную персональную политику
      # установил значение
      group_policy= Factory.create(:page_manager_group_policy,
        :role_id=>page_manager_role.id,
        :value=>false
      )
      # Просто так - если у пользователя несколько персональных политик
      Factory.create(:page_tree_group_policy,
        :role_id=>page_manager_role.id,
        :value=>true
      )
      # блокировка актуальна
      admin_user.has_group_block?(:pages, :manager, :recalculate=> true).should be_true
      # Различные значения блокирующей политики
      group_policy.update_attribute(:value, false)
      admin_user.has_group_block?(:pages, :manager, :recalculate=> true).should be_true
      # p admin_user.group_policies_hash
      # Актуально - но значения не подподают под разряд false
      group_policy.update_attribute(:value, true)
      admin_user.has_group_block?(:pages, :manager, :recalculate=> true).should be_false
      # Вернуть значение блокировки
      group_policy.update_attribute(:value, false)
      admin_user.has_group_block?(:pages, :manager, :recalculate=> true).should be_true
      # Актуальность
      # Кол-во: актуально, Время: актуально
      group_policy.update_attributes({:counter=>10, :max_count=>10})
      admin_user.has_group_block?(:pages, :manager, :recalculate=> true).should be_true
      # Кол-во: не актуально, Время: актуально
      group_policy.update_attributes({:counter=>10, :max_count=>9})
      admin_user.has_group_block?(:pages, :manager, :recalculate=> true).should be_false
      # Кол-во: актуально, Время: не актуально
      group_policy.update_attributes({:counter=>10, :max_count=>10, :start_at=>1.day.ago, :finish_at=>1.second.ago})
      admin_user.has_group_block?(:pages, :manager, :recalculate=> true).should be_false
      # Кол-во: не актуально, Время: не актуально
      group_policy.update_attributes({:counter=>10, :max_count=>9, :start_at=>1.day.ago, :finish_at=>1.second.ago})
      admin_user.has_group_block?(:pages, :manager, :recalculate=> true).should be_false
      # Снова Кол-во: актуально, Время: актуально
      group_policy.update_attributes({:counter=>10, :max_count=>11, :start_at=>1.day.ago, :finish_at=>1.day.from_now})
      admin_user.has_group_block?(:pages, :manager, :recalculate=> true).should be_true
    end#12:48 16.07.2009
  end#GroupPolicyOutputData has_group_block?

  describe 'GroupPolicyOutputData has_group_access?' do
    # Проверить корректность возвращения результата проверки на доступ
    # Различные форматы значений, которые могут хранится в БД
    it '13:34 15.07.2009' do
      # Создать роль и админа с этой ролью
      page_manager_role= Factory.create(:page_manager_role)
      admin_user= Factory.create(:admin,
        :role_id=>page_manager_role.id
      )
      # Различные варианты ввода данных
      # true
      group_policy= Factory.create(:page_manager_group_policy,
        :role_id=>page_manager_role.id,
        :value=>true
      )
      # Просто так - если у пользователя несколько персональных политик
      Factory.create(:page_tree_group_policy,
        :role_id=>page_manager_role.id,
        :value=>true
      )
      #true
      admin_user.has_group_access?(:pages, :manager, :recalculate=> true).should be_true
      #false
      group_policy.update_attribute(:value, false)
      admin_user.has_group_access?(:pages, :manager, :recalculate=> true).should be_false
      # обновлено, но не установлен флаг пересчета - должно сохранятся предыдущее значение
      group_policy.update_attribute(:value, true)
      admin_user.has_group_access?(:pages, :manager).should be_false
      # ничего не обнавляем, но просим пересчитать хеш доступа согласно данных в БД
      admin_user.has_group_access?(:pages, :manager, :recalculate=> true).should be_true
    end#13:34 15.07.2009
  end#GroupPolicyOutputData has_group_access?
  
###################################################################################################
# Персональная политика к рсурсу 
###################################################################################################
  
  describe 'PersonalResourcePolicy' do
    it '17:23 16.07.2009' do
      admin= Factory.create(:admin)
      ivanov= Factory.create(:ivanov)
      # Проверим (немного) работу взаимосвязей между моделями
      test_personal_resource_policy= admin.personal_resource_policies.new
      test_personal_resource_policy.should be_instance_of(PersonalResourcePolicy)
      test_personal_resource_policy.save.should be_true
      personal_resource_policy= Factory.create(:page_manager_personal_resource_policy,
        :user_id=>admin.id
      )
      # Работа полиморфа
      personal_resource_policy.resource= ivanov
      personal_resource_policy.save
      personal_resource_policy.resource_id.should   == ivanov.id
      personal_resource_policy.resource_type.should == ivanov.class.to_s
    end
    
    # Создать пользователю персональные политики к различным объектам
    it '13:05 17.07.2009' do
      admin= Factory.create(:admin)
      ivanov= Factory.create(:ivanov)
      petrov= Factory.create(:petrov)

      # У пользователя еще нет ни одного персонального права - должно вернуть false
      admin.has_personal_resource_access_for?(ivanov, :profile, :edit).should be_false
            
      # Пользователь обладает персональной политикой к ресурсу пользователь
      personal_resource_policy0= Factory.create(:profile_edit_personal_resource_policy,
        :user_id=>admin.id  
      )
      personal_resource_policy0.resource= ivanov
      personal_resource_policy0.save
      # Пользователь обладает персональной политикой к ресурсу пользователь
      personal_resource_policy1= Factory.create(:profile_edit_personal_resource_policy,
        :user_id=>admin.id  
      )
      # установить подчиненный объект
      personal_resource_policy1.resource= petrov
      personal_resource_policy1.save
      # Проверка на синтаксические ошибки в функции
      admin.has_personal_resource_access_for?(ivanov, :profile, :edit, :recalculate=>true).should be_true      
    end# 13:05 17.07.2009
  end#PersonalResourcePolicy
  
  def my_helper_method
    # А так можно оформить любой необходимый хелпер
    # Вобщем любую функцию, которая может сократить тест
  end
end
