require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe PagesController do
  # Работоспособность маршрутизации

  it "20:46 23.07.2009" do
    route_for(:controller => 'pages', :action => 'index').should == '/pages/'
    route_for(:controller => 'pages', :action => 'show', :id=>'1').should == '/pages/show/1'
  end
  
  it "20:47 23.07.2009" do
    params_from(:get, "/pages/show/2").should == {:controller => 'pages', :action => 'show', :id=>'2'}
    params_from(:get, "/pages/show/17").should == {:controller => 'pages', :action => 'show', :id=>'17'}
  end
  
  it "20:48 23.07.2009" do
    params_from(:get, user_pages_path(:user_id=>1)).should == {:controller => 'pages', :action => 'index', :user_id=>'1'}
    params_from(:get, user_pages_path(:user_id=>'admin')).should == {:controller => 'pages', :action => 'index', :user_id=>'admin'}
    user_pages_path(:user_id=>'petrov', :subdomain=>'admin').should == 'http://admin.test.host/users/petrov/pages'
    params_from(:get, user_pages_url(:user_id=>'petrov', :subdomain=>'admin')).should == {:controller => 'pages', :action => 'index', :user_id=>'petrov'}
  end
end