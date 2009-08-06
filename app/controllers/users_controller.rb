class UsersController < ApplicationController
  # Формирование данных для отображения базового меню-навигации
  before_filter :navigation_menu_init
  
  # базовая страница Пользователя системы
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
    
    # Создать пользователя
    # Назначить роль зарегистрированного пользователя
    # Сохранить
    @user = User.new(params[:user])
    @user.set_role(Role.find_by_name('registrated_user'))
    @user.save
        
    if @user.errors.empty?
      # Если все успешно - создадим пользователю пустой профайл
      Profile.new(:user_id=>@user.id).save
      
      self.current_user = @user
      redirect_back_or_default('/')
      flash[:notice] = t('user.entered')
    else
      flash[:notice] = t('user.cant_be_create')
      flash[:warning] = t('server.error')
      render :action => 'new'
    end
  end

end
