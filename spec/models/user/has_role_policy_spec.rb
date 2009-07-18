require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

###################################################################################################
# Тестирование базовой функции проверки политики
###################################################################################################

describe '14:54 18.07.2009' do   
  # Должен иметь роль и политику доступа к просмотру pages[:tree]
  it '17:40 14.07.2009' do
    # Создать роль
    # Создать пользователя с данной ролью
    page_manager_role= Factory.create(:page_manager_role)
    admin_user= Factory.create(:admin,
      :role_id=>page_manager_role.id
    )
    # Должен быть хеш политик из стандартной роли
    admin_user.role_policies_hash.should be_instance_of(Hash)
    # Должно быть два правила доступа
    # Обратимся и через строку и через символ
    admin_user.has_role_policy?('pages', 'tree').should be_true
    admin_user.has_role_policy?(:pages, :manager).should be_true
    # Этого правила быть не должно
    admin_user.has_role_policy?(:pages, :some_stupid_policy).should be_false
  end#17:40 14.07.2009

  # Проверка базовых политик
  it '12:51 18.07.2009' do
    page_manager_role= Factory.create(:page_manager_role)
    @admin= Factory.create(:admin, :role_id=>page_manager_role.id)
    
    @admin.has_role_policy?(:pages, :tree).should     be_true
    @admin.has_role_policy?(:pages, :manager).should  be_true
    
    @admin.has_role_policy?(:page, :duck).should      be_false
    @admin.has_role_policy?(:pages, :duck).should     be_false
    
    @admin.has_role_policy?(:blocked, :yes).should    be_false
    @admin.has_role_policy?(:blocked, :no).should     be_true
  end# 12:51 18.07.2009
        
end
