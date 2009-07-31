require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe PagesController do
    before(:each) do
      @admin= Factory.create(:admin)
      @ivanov= Factory.create(:ivanov)
      @petrov= Factory.create(:petrov)
    end
    
    # действие index
    
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
end