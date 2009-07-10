require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

p '=> Page Test'

describe PagesController do
  before(:each) do
    Factory.define :user do |u| end
    
    Factory.create(:user,
      :login => 'killich',
      :email => 'test@admin.ru',
      :crypted_password=>'mega',
      :salt=>'salt',
      :name=>'Зыкин Илья Николаевич'
    )

    #@current_user = mock_model(User, :id => 1)
    #controller.stub!(:current_user).and_return(@current_user)
    #controller.stub!(:login_required).and_return(:true)
    
    #@current_user = User.find :first
    #controller.stub!(:current_user).and_return(@current_user)
    #controller.stub!(:login_required).and_return(:true)    
  end

  #Контроллер должен быть контроллером PagesController
  it "should use PagesController" do
    controller.should be_an_instance_of(PagesController)
  end

  describe "GET 'index'" do
    it "should be successful" do
      #User.authenticate('iv36', 'iv36')
      #test_session= SessionsController.new
      #@params={:login=>'iv36', :password=>'iv36'}
      #p test_session.params.class
      #test_session.params={:login=>'iv36', :password=>'iv36'}
      #p test_session.params.class
      #test_session.create
      
      controller.test_user
      get 'index'
      #@pages_tree.should be_nil
      #@current_user.should be_nil
      #controller.current_user.id.should eql(1)
      #controller.stub!(:current_user=) 
      #controller.stub!:(current_user).and_return(@user)
      #controller.instance_variables_get('@pages_tree')
      assigns[:pages_tree].should be_instance_of(Array)
      assigns[:pages_tree].should be_empty
      p assigns[:test_user].class
      p assigns[:test_user].login
      response.should be_success
    end
  end
end
