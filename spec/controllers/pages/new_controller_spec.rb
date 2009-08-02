require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

=begin
    # new - на создание своей страницы ведут ссылки  
      #'/pages/new'
      #'http://test.host/pages/new'
      #'http://current_user.test.host/pages/new'
      #'/users/current_user/pages/new'
      #'http://other_user.test.host/users/current_user/pages/new'

      current_subdomain= nil
      current_user= me
      @user= 
      
      current_subdomain= me
      current_user= me
      @user= 

    # new - на создание чужой страницы ведут ссылки
      #'http://other_user.test.host/pages/new'
      #'http://current_user.test.host/users/other_user/pages/new'
      #'http://test.host/users/other_user/pages/new'
      #'/users/other_user/pages/new'

      controller.stub!(:current_user).and_return(@user[:ivanov])
      controller.stub!(:current_subdomain).and_return(@user[:petrov].login)      
=end

describe PagesController do
    before(:all) do
      @registrated_user_role=    Factory.create(:registrated_user_role)
      @guaranted_user_role=      Factory.create(:guaranted_user_role)
      @site_administrator_role=  Factory.create(:site_administrator_role)
      @page_administrator_role=  Factory.create(:page_administrator_role)
      @administrator_role=       Factory.create(:administrator_role)
      
      # Имеет доступ к new страниц всех пользователей
      @admin= Factory.create(:admin)
      @admin.update_role(@administrator_role)
      
      # Имеет доступ к new страниц всех пользователей
      @page_administrator= Factory.create(:empty_user, :login=>'page_administrator', :email=>'page_administrator@email.com')
      @page_administrator.update_role(@page_administrator_role)
      
      # Имеет доступ только к new только своей страницы
      @site_administrator= Factory.create(:empty_user, :login=>'site_administrator_role', :email=>'site_administrator@email.com')
      @site_administrator.update_role(@site_administrator_role)
      
      # Не имеет никакого доступа к new
      @guaranted_user= Factory.create(:empty_user, :login=>'guaranted_user', :email=>'guaranted_user@email.com')
      @guaranted_user.update_role(@guaranted_user_role)
      
      # Не имеет никакого доступа к new
      @registrated_user= Factory.create(:empty_user, :login=>'registrated_user', :email=>'registrated_user@email.com')
      @registrated_user.update_role(@registrated_user_role)
    end

    # У пользователей те роли, которые требуются
    it "18:24 23.07.2009" do
      @admin.role.name.should                 eql('administrator')
      @page_administrator.role.name.should    eql('page_administrator')
      @site_administrator.role.name.should    eql('site_administrator')
      @guaranted_user.role.name.should        eql('guaranted_user')
      @registrated_user.role.name.should      eql('registrated_user')
    end
    
    # new routing
    it "18:24 23.07.2009" do
      new_page_path.should == '/pages/new'
      new_page_url.should == 'http://test.host/pages/new'
      new_page_path(:subdomain=>@admin.login).should == 'http://admin.test.host/pages/new'
      new_page_url(:subdomain=>@admin.login).should == 'http://admin.test.host/pages/new'
      
      new_user_page_path( :user_id=>@admin.login).should == '/users/admin/pages/new'
      new_user_page_url(  :user_id=>@admin.login).should == 'http://test.host/users/admin/pages/new'
      new_user_page_path( :user_id=>@admin.login, :subdomain=>@admin.login).should == 'http://admin.test.host/users/admin/pages/new'
      new_user_page_url(  :user_id=>@admin.login, :subdomain=>@admin.login).should == 'http://admin.test.host/users/admin/pages/new'
    end
    

    it "18:24 23.07.2009" do

    end
    

    it "18:24 23.07.2009" do

    end

      #get :new
      #response.should be_success
      #response.should render_template("pages/index.haml")
          
    # действие index
=begin
    # Нет никаких данных в системе
    it "18:24 23.07.2009" do
      controller.stub!(:current_subdomain).and_return(@admin.login)
      
      get :index
      
      assigns[:user].should eql(@admin)
      assigns[:pages_tree].should be_empty
    end
    
    # Зашли в поддомен @petrov
    it "18:42 23.07.2009" do
      controller.stub!(:current_subdomain).and_return(@petrov.login)
      
      get :index
      
      assigns[:user].should eql(@petrov)
      assigns[:pages_tree].should be_empty
    end
    
    # Зашли в поддомен @petrov, но путь вида /users/1/pages приоритетнее
    # Войдем под администратором
    it "18:42 23.07.2009" do
      controller.stub!(:current_subdomain).and_return(@petrov.login)
      
      #user_pages_path(:user_id=>@admin.id)
      get '/users/admin/pages', :user_id=>@admin.login
      assigns[:user].should eql(@admin)
      
      get '/users/ivanov/pages', :user_id=>@ivanov.id
      assigns[:user].should eql(@ivanov)
      #assigns[:pages_tree].should be_empty
    end
=end
end