require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

p '=> ADMIN Test'

describe AdminsController do

  #Delete these examples and add some real ones
  it "should use AdminsController" do
    controller.should be_an_instance_of(AdminsController)
  end


  describe "GET 'index'" do
    it "should be successful" do
      get 'index'
      response.should be_success
    end
  end
end
