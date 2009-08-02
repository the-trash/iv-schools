require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe PagesController do
    # Создать zip код для страницы
    def create_zip_for_page
      zip= "#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}"
      while Page.find_by_zip(zip)
        zip= "#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}"
      end
      zip
    end
    
    before(:all) do
      # Создать роли
      @registrated_user_role=    Factory.create(:registrated_user_role)
      @guaranted_user_role=      Factory.create(:guaranted_user_role)
      @site_administrator_role=  Factory.create(:site_administrator_role)
      @page_administrator_role=  Factory.create(:page_administrator_role)
      @administrator_role=       Factory.create(:administrator_role)
      
      # Имеет доступ к edit страниц всех пользователей
      @admin= Factory.create(:admin)
      @admin.update_role(@administrator_role)
      @admin_page= Factory.create(:test_page, :user_id=>@admin.id, :zip=>create_zip_for_page)
      
      # Имеет доступ к edit страниц всех пользователей
      @page_administrator= Factory.create(:empty_user, :login=>'page_administrator', :email=>'page_administrator@email.com')
      @page_administrator.update_role(@page_administrator_role)
      @page_administrator_page= Factory.create(:test_page, :user_id=>@page_administrator.id, :zip=>create_zip_for_page)
      
      # Имеет доступ только к edit только своей страницы
      @site_administrator= Factory.create(:empty_user, :login=>'site_administrator_role', :email=>'site_administrator@email.com')
      @site_administrator.update_role(@site_administrator_role)
      @site_administrator_page= Factory.create(:test_page, :user_id=>@site_administrator.id, :zip=>create_zip_for_page)
      
      # Не имеет никакого доступа к edit
      @guaranted_user= Factory.create(:empty_user, :login=>'guaranted_user', :email=>'guaranted_user@email.com')
      @guaranted_user.update_role(@guaranted_user_role)
      
      # Не имеет никакого доступа к edit
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
    
    # У нужных пользователей есть страницы
    it "18:24 23.07.2009" do
      @admin.pages.should have(1).item
      @page_administrator.pages.should have(1).item
      @site_administrator.pages.should have(1).item
      @guaranted_user.pages.should have(:no).items
      @registrated_user.pages.should have(:no).items
    end
    
    # pages::edit routing    
    it "18:24 23.07.2009" do
      edit_page_path(:id=>1).should == '/pages/1/edit'
      edit_page_url(:id=>1).should == 'http://test.host/pages/1/edit'
      edit_page_path(:subdomain=>@admin.login, :id=>1).should == 'http://admin.test.host/pages/1/edit'
      edit_page_url(:subdomain=>@admin.login, :id=>1).should == 'http://admin.test.host/pages/1/edit'
      
      edit_user_page_path(:user_id=>@admin.login, :id=>1).should == '/users/admin/pages/1/edit'
      edit_user_page_url( :user_id=>@admin.login, :id=>1).should == 'http://test.host/users/admin/pages/1/edit'
      edit_user_page_path(:subdomain=>@admin.login, :user_id=>@admin.login, :id=>1).should == 'http://admin.test.host/users/admin/pages/1/edit'
      edit_user_page_url( :subdomain=>@admin.login, :user_id=>@admin.login, :id=>1).should == 'http://admin.test.host/users/admin/pages/1/edit'
      
      params_from(:get, '/pages/1/edit').should == {:controller => 'pages', :action => 'edit', :id=>'1'}
      params_from(:get, '/users/admin/pages/1/edit').should == {:controller => 'pages', :action => 'edit', :user_id=>'admin', :id=>'1'}
    end
=begin
#---------------------------------------------------------------
# АДМИНИСТРАТОР
#---------------------------------------------------------------
    
    # Администратор заходит к себе
    # current_user= @admin
    # @user= @admin
    it "14:02 02.08.2009" do
      controller.stub!(:current_user).and_return(@admin)
      controller.stub!(:current_subdomain).and_return(@admin.login)

      # de facto: get 'http://admin.test.host/pages/new'
      get :new 
      
      assigns[:user].should eql(@admin)
      response.should render_template("pages/new.haml")
      response.should be_success
    end
    
    # Администратор заходит к себе
    # current_user= @admin
    # @user= @admin
    it "14:35 02.08.2009" do
      controller.stub!(:current_user).and_return(@admin)
      
      # de facto: get 'http://test.host/users/admin/pages/new'
      get :new, :user_id=>'admin'
      
      assigns[:user].should eql(@admin)
      response.should render_template("pages/new.haml")
      response.should be_success
    end
    
    # Администратор заходит к себе
    # current_user= @admin
    # @user= @admin
    it "14:35 02.08.2009" do
      controller.stub!(:current_user).and_return(@admin)
      
      # de facto: get 'http://test.host/pages/new'
      get :new
      
      assigns[:user].should eql(@admin)
      response.should render_template("pages/new.haml")
      response.should be_success
    end
    
    # Администратор заходит к зарегистрированному пользователю
    # current_user= @admin
    # @user= @registrated_user
    it "14:02 02.08.2009" do
      controller.stub!(:current_user).and_return(@admin)
      controller.stub!(:current_subdomain).and_return(@registrated_user.login)

      # de facto: get 'http://registrated_user.test.host/pages/new'
      get :new
      
      assigns[:user].should eql(@registrated_user)
      response.should render_template("pages/new.haml")
      response.should be_success

      # А вот сам зарегистрированный пользователь зайти в new не может не может
      # current_user= @registrated_user
      # @user= @registrated_user
          
      controller.stub!(:current_user).and_return(@registrated_user)
      controller.stub!(:current_subdomain).and_return(@registrated_user.login)

      # de facto: get 'http://registrated_user.test.host/pages/new'
      get :new
      
      assigns[:user].should eql(@registrated_user)
      response.should_not be_success
      response.should redirect_to(new_session_path)      
    end
    
#---------------------------------------------------------------
# АДМИНИСТРАТОРА ШКОЛЬНОГО САЙТА
#---------------------------------------------------------------

    # Администратор школьного сайта заходит к себе
    # current_user= @site_administrator
    # @user= @site_administrator
    it "15:43 02.08.2009" do
      controller.stub!(:current_user).and_return(@site_administrator)
      controller.stub!(:current_subdomain).and_return(@site_administrator.login)

      # de facto: get 'http://site_administrator.test.host/pages/new'
      get :new
      
      assigns[:user].should eql(@site_administrator)
      response.should render_template("pages/new.haml")
      response.should be_success
    end
    
    # Администратор школьного сайта заходит к себе
    # current_user= @site_administrator
    # @user= @site_administrator
    it "15:43 02.08.2009" do
      controller.stub!(:current_user).and_return(@site_administrator)

      # de facto: get 'http://test.host/users/site_administrator/pages/new'
      get :new, :user_id=>'site_administrator'
      
      assigns[:user].should eql(@site_administrator)
      response.should render_template("pages/new.haml")
      response.should be_success
    end
    
    # Администратор школьного сайта заходит к себе
    # current_user= @site_administrator
    # @user= @site_administrator
    it "15:43 02.08.2009" do
      controller.stub!(:current_user).and_return(@site_administrator)

      # de facto: get 'http://test.host/pages/new'
      get :new
      
      assigns[:user].should eql(@site_administrator)
      response.should render_template("pages/new.haml")
      response.should be_success
    end

    # Администратор школьного сайта заходит к администратору портала
    # current_user= @site_administrator
    # @user= @admin
    it "15:43 02.08.2009" do
      controller.stub!(:current_user).and_return(@site_administrator)
      controller.stub!(:current_subdomain).and_return(@admin.login)
      
      # de facto: get 'http://admin.test.host/pages/new'
      get :new
      
      assigns[:user].should eql(@admin)
      response.should_not be_success
      response.should redirect_to(new_session_path)
    end
    
    # Администратор школьного сайта заходит к администратору
    # current_user= @site_administrator
    # @user= @admin
    it "15:43 02.08.2009" do
      controller.stub!(:current_user).and_return(@site_administrator)
      #controller.stub!(:current_subdomain).and_return(@admin.login)
      
      # de facto: get 'http://test.host/users/admin/pages/new'
      get :new, :user_id=>'admin'
      
      assigns[:user].should eql(@admin)
      response.should_not be_success
      response.should redirect_to(new_session_path)
    end
    
    # Администратор школьного сайта заходит к себе
    # current_user= @site_administrator
    # @user= @site_administrator
    it "15:43 02.08.2009" do
      controller.stub!(:current_user).and_return(@site_administrator)
      controller.stub!(:current_subdomain).and_return(@admin.login)
      
      # de facto: get 'http://admin.test.host/users/site_administrator/pages/new'
      get :new, :user_id=>@site_administrator.login
      
      assigns[:user].should eql(@site_administrator)
      response.should render_template("pages/new.haml")
      response.should be_success
    end
    
    # Администратор школьного сайта заходит к admin
    # current_user= @site_administrator
    # @user= @site_administrator
    it "15:43 02.08.2009" do
      controller.stub!(:current_user).and_return(@site_administrator)
      controller.stub!(:current_subdomain).and_return(@admin.login)
      
      # de facto: get 'http://site_administrator.test.host/users/admin/pages/new'
      get :new, :user_id=>@admin.login
      
      assigns[:user].should eql(@admin)
      response.should_not be_success
      response.should redirect_to(new_session_path)
    end
    
#---------------------------------------------------------------
# ГОСТЬ
#---------------------------------------------------------------
  
    # Гость заходит к адмиистратору
    # current_user= nil
    # @user= @admin
    it "14:02 02.08.2009" do
      controller.stub!(:current_subdomain).and_return(@admin.login)

      get :new # de facto: get 'http://admin.test.host/pages/new'
      
      assigns[:user].should eql(@admin)
      response.should_not be_success
      response.should redirect_to(new_session_path)
    end
    
    # Гость заходит к адмиистратору
    # current_user= nil
    # @user= @admin
    it "14:02 02.08.2009" do
      # de facto: get 'http://test.host/users/admin/pages/new'
      get :new, :user_id=>'admin'
      
      assigns[:user].should eql(@admin)
      response.should_not be_success
      response.should redirect_to(new_session_path)
    end
    
    # Гость заходит к адмиистратору (@user=User.find(:first))
    # current_user= nil
    # @user= @admin
    it "14:02 02.08.2009" do
      # de facto: get 'http://test.host/pages/new'
      get :new
      
      assigns[:user].should eql(@admin)
      response.should_not be_success
      response.should redirect_to(new_session_path)
    end
=end
end