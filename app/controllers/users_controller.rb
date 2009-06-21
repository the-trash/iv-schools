class UsersController < ApplicationController
  # ‘ормирование данных дл€ отображени€ базового меню-навигации
  before_filter :navigation_menu_init
  
  # базова€ страница ѕользовател€ системы
  def index
    @pages_tree= Page.find_all_by_user_id(@user.id, :order=>"lft ASC")
  end
  
  # render new.rhtml
  def new
    @user = User.new
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @user = User.new(params[:user])
    @user.save
    if @user.errors.empty?
      self.current_user = @user
      redirect_back_or_default('/')
      flash[:notice] = Message::USER_LOGINED
    else
      flash[:notice] = Message::USER_CANT_CREATE
      flash[:warning] = Message::SERVER_ERROR
      render :action => 'new'
    end
  end

end
