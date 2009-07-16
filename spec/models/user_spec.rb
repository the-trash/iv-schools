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
    admin_user.role_settings_hash.should be_instance_of(Hash)
    # Должно быть два правила доступа
    # Обратимся и через строку и через символ
    admin_user.has_policy?('pages', 'tree').should be_true
    admin_user.has_policy?(:pages, :manager).should be_true
    # Этого правила быть не должно
    admin_user.has_policy?(:pages, :some_stupid_policy).should be_false
  end#17:40 14.07.2009
  
  
  # Отработка Персональных политик
  describe PersonalPolicy do
    
    it '9:17 15.07.2009, Отработать функцию has_personal_policy?(:section, :action)' do
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
      admin_user.has_personal_policy?(:pages, :manager).should be_true
      # Таких прав не существует - вернуть nil
      admin_user.has_personal_policy?(:pages0,  :tree).should be_nil
      admin_user.has_personal_policy?(:pages,   :duck).should be_nil
    end#9:17 15.07.2009
    
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
      p admin_user.personal_policy_settings_hash
      admin_user.has_personal_policy?(:pages, :manager).should be_false
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
      admin_user.has_personal_policy?(:pages, :manager).should be_false
    end#11:48 15.07.2009
    
  end#PersonalPolicy
  
  describe 'PersonalPolicyOutputData' do
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
      #true
      admin_user.has_personal_policy?(:pages, :manager, true).should be_true
      personal_policy.update_attribute(:value, 'true')
      admin_user.has_personal_policy?(:pages, :manager, true).should be_true
      personal_policy.update_attribute(:value, '1')
      admin_user.has_personal_policy?(:pages, :manager, true).should be_true
      personal_policy.update_attribute(:value, 1)
      admin_user.has_personal_policy?(:pages, :manager, true).should be_true
      #false
      personal_policy.update_attribute(:value, false)
      admin_user.has_personal_policy?(:pages, :manager, true).should be_false
      personal_policy.update_attribute(:value, 'false')
      admin_user.has_personal_policy?(:pages, :manager, true).should be_false
      personal_policy.update_attribute(:value, '0')
      admin_user.has_personal_policy?(:pages, :manager, true).should be_false
      personal_policy.update_attribute(:value, 0)
      admin_user.has_personal_policy?(:pages, :manager, true).should be_false
      #nil
      personal_policy.update_attribute(:value, nil)
      admin_user.has_personal_policy?(:pages, :manager, true).should be_nil
      personal_policy.update_attribute(:value, 'nil')
      admin_user.has_personal_policy?(:pages, :manager, true).should be_nil
      personal_policy.update_attribute(:value, '')
      admin_user.has_personal_policy?(:pages, :manager, true).should be_nil
      
      # обновлено, но не установлен флаг пересчета - должно сохранятся предыдущее значение
      personal_policy.update_attribute(:value, true)
      admin_user.has_personal_policy?(:pages, :manager).should be_nil
      # ничего не обнавляем, но просим пересчитать хеш доступа согласно данных в БД
      admin_user.has_personal_policy?(:pages, :manager, true).should be_true
      
    end#13:34 15.07.2009
  end#PersonalPolicyOutputData

  def my_helper_method
    # А так можно оформить любой необходимый хелпер
    # Вобщем любую функцию, которая может сократить тест
  end
  
end
