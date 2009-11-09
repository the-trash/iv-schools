class PagesController < ApplicationController  
  # Формирование данных для отображения базового меню-навигации
  # Проверка на регистрацию
  # Поиск ресурса для обработчиков, которым он требуется
  # Исправить адрес по которому обращается пользователь к ресурсу
  # Проверка на политику доступа к обработчику, который не требует конкретного ресурса
  # Проверка на политику доступа к обработчику, который требует ресурс
  before_filter :navigation_menu_init,                  :except=> [:show, :edustat, :first]  
  before_filter :login_required,                        :except=> [:index, :show, :edustat, :first]
  before_filter :find_page,                             :only=>   [:show, :edit, :update, :destroy, :up, :down]
  before_filter :fix_url_by_redirect,                   :only=>   [:show]
  before_filter :access_to_controller_action_required,  :only=>   [:new, :create, :manager]
  before_filter :page_resourсe_access_required,         :only=>   [:edit, :update, :destroy, :up, :down]

  # Карта сайта
  # Выбрать дерево страниц, только те поля, которые учавствуют отображении
  def index
    @pages_tree= Page.find_all_by_user_id(@user.id, :select=>'id, title, zip, parent_id', :order=>"lft ASC")
  end
  
  def first
    @page= Page.find_all_by_user_id(@user.id, :order=>"lft ASC", :limit=>1).first
    @parents= @page.self_and_ancestors if @page
    @siblings= @page.children if @page
  end

  def show
    @page= Page.find_by_zip(params[:id])
    # Действительный владелец страницы
    @page_subdomain= @user.is_owner_of?(@page) ? @user.subdomain : @page.user.subdomain
    @parents= @page.self_and_ancestors if @page
    @siblings= @page.children if @page
  end
  
  # Карта сайта редактора
  def manager
    @pages_tree= Page.find_all_by_user_id(@user.id, :order=>"lft ASC")
  end
  
  def new
    @parent= nil
    @parent= Page.find_by_zip(params[:parent_id]) if params[:parent_id]
    @page= Page.new
  end
  
  def create
    @page= Page.new(params[:page])
    @parent= nil
    @parent= Page.find_by_zip(params[:parent_id]) if params[:parent_id]
    #zip= zip_for_model('Page')
    #@page.zip= zip
    @page.user_id= @user.id 
    respond_to do |format|
      if @page.save
        @page.move_to_child_of(@parent) if @parent
        flash[:notice] = t('page.created')
        format.html { redirect_to(edit_page_path(@page.zip)) }
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  def edit
    # before_filter
  end
  
  # PUT /pages/2343-5674-3345
  def update
    respond_to do |format|
      if @page.update_attributes(params[:page])
        flash[:notice] = t('page.updated')
        format.html { redirect_back_or(manager_pages_path(:subdomain=>@subdomain)) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def up
    if @page.move_possible?(@page.left_sibling)
      @page.move_left
      flash[:notice] = t('page.up')
    else
      flash[:notice] = t('page.cant_move')
    end
    redirect_to(manager_pages_path(:subdomain=>@subdomain)) and return
  end
  
  def down
    if @page.move_possible?(@page.right_sibling)
      @page.move_right
      flash[:notice] = t('page.down')
      redirect_to(manager_pages_path(:subdomain=>@subdomain)) and return
    else
      flash[:notice] = t('page.cant_be_move')
      redirect_to(manager_pages_path(:subdomain=>@subdomain)) and return
    end
  end

  def destroy
    if @page.children.count.zero?
      @page.destroy
      flash[:notice]= t('page.deleted')
    else
      flash[:notice]= t('page.has_children')
    end
    redirect_to(manager_pages_path(:subdomain=>@subdomain)) and return
  end
  
  # Статистика для департамента
  def edustat
    #iv36 id-5
    @lc43= Page.find_by_user_id(6, :order=>'created_at DESC', :limit=>1)
    @lu43= Page.find_by_user_id(6, :order=>'updated_at DESC', :limit=>1)
    #iv43 id-6
    @lc36= Page.find_by_user_id(5, :order=>'created_at DESC', :limit=>1)
    @lu36= Page.find_by_user_id(5, :order=>'updated_at DESC', :limit=>1)

    respond_to do |format|
      format.php  { render :action => 'edustat', :layout => false }
      format.html { render :action => 'edustat', :layout => false }
      format.any  { render :template => 'pages/edustat.html', :layout => false }
    end
  end
 
  protected

  def find_page
    @page= Page.find_by_zip(params[:id])
    access_denied and return unless @page
  end
  
  def fix_url_by_redirect
    return true if @user.is_owner_of?(@page)
    redirect_to page_url(@page.zip, :subdomain=>@page.user.subdomain)
  end
  
  def access_to_controller_action_required
    access_denied if current_user.has_complex_block?(:administrator, controller_name)
    return true   if current_user.has_complex_access?(:administrator, controller_name)
    return true   if current_user.has_role_policy?(:administrator, controller_name)
    access_denied if current_user.has_complex_block?(controller_name, action_name)
    return true   if current_user.has_complex_access?(controller_name, action_name) && current_user.is_owner_of?(@user)
    return true   if current_user.has_role_policy?(controller_name, action_name) && current_user.is_owner_of?(@user)
    access_denied
  end
  
  def page_resourсe_access_required
      access_denied if current_user.has_complex_resource_block_for?(@page, :administrator, controller_name)
      return true   if current_user.has_complex_resource_access_for?(@page, :administrator, controller_name)
      return true   if current_user.has_role_policy?(:administrator, controller_name)
      access_denied if current_user.has_complex_block?(:administrator, controller_name)
      return true   if current_user.has_complex_access?(:administrator, controller_name)
      access_denied if current_user.has_complex_resource_block_for?(@page, controller_name, action_name)
      return true   if current_user.has_complex_resource_access_for?(@page, controller_name, action_name)
      access_denied if current_user.has_complex_block?(controller_name, action_name)
      return true   if current_user.has_complex_access?(controller_name, action_name)
      return true   if current_user.has_role_policy?(controller_name, action_name) && current_user.is_owner_of?(@page)
      access_denied
  end
  
  # for :new, :create, :manager
  # :administrator, :pages
  # :pages, :new
  # Пользователь - владелец объекта и имеет соответствующие ролевые политики
  # Под объектом предполагается просматриваемый пользователь (текущий и просматриваемый должны совпадать)
  # !!!!! TODO: НАПИСАТЬ ТЕСТ: ИМЕЕТ ГРУППОВОЙ ДОСТУП К ДЕЙСТВИЮ, НО ПРОСМАТРИВАЕТ НЕ СЕБЯ !!!!!
  
  # for :edit, :update, :destroy, :up, :down
  # :administrator, :pages
    # Есть персональные или групповые блокировки к ресурсу
    # Есть персональные или групповые разрешения к ресурсу (они выше по приоритету, чем общие блокировки)
    # Есть персональные или групповые блокировки
    # Есть персональные или групповые разрешения
  # :pages, :edit
    # Есть персональные или групповые блокировки к ресурсу
    # Есть персональные или групповые разрешения к ресурсу (они выше по приоритету, чем общие блокировки)
    # Есть персональные или групповые блокировки
    # Есть персональные или групповые разрешения
    # Пользователь - владелец ресурса и имеет соответствующие ролевые политики
    # Под ресурсом предполагается объект принадлежащий пользователю (текущий пользователь редактирует состояния своих объектов)
end