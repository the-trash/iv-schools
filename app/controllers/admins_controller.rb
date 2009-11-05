class AdminsController < ApplicationController
  before_filter :login_required
  
  layout 'admin_application.haml'
  
  def index
  end
end
