class PagesController < ApplicationController  
  # Формирование данных для отображения базового меню-навигации
  before_filter :navigation_menu_init, :except=>[:show]  
  
  # Проверка на регистрацию
  before_filter :login_required, :except=>[:index, :show]
  
  # Проверка на общую политику доступа к действию контроллера
  before_filter :access_to_controller_action_required, :only=>[:new, :create, :manager]
  
  # Проверка доступа к действию над ресурсом
  before_filter :page_resourсe_access_required, :only=>[:show, :edit, :update, :destroy, :up, :down]

  # Карта сайта
  def index  
    # Выбрать дерево страниц, только те поля, которые учавствуют отображении
    @pages_tree= Page.find_all_by_user_id(@user.id, :select=>'id, title, zip, parent_id', :order=>"lft ASC")
  end

  def show
    @page= Page.find_by_zip(params[:id])
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
    zip= "#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}"
    while Page.find_by_zip(zip)
      zip= "#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}"
    end
    @page.zip= zip
    @page.user_id= @user.id 
    respond_to do |format|
      if @page.save
        @page.move_to_child_of(@parent) if @parent
        flash[:notice] = Messages::Pages[:created]
        format.html { redirect_to(edit_page_path(@page.zip)) }
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  def edit
    @page= Page.find_by_zip(params[:id])
  end
  
  # PUT /pages/2343-5674-3345
  def update
    @page = Page.find_by_zip(params[:id])    
    respond_to do |format|
      if @page.update_attributes(params[:page])
        flash[:notice] = Messages::Pages[:updated]
        format.html { redirect_back_or(manager_pages_path(:subdomain=>@subdomain)) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def up
    @page= Page.find_by_zip(params[:id])
    if @page.move_possible?(@page.left_sibling)                     # Если возможно переместить вверх
      @page.move_left                                               # Перемещаем
      flash[:notice] = Messages::NestedSet[:element][:up]
    else
      flash[:notice] = Messages::NestedSet[:element][:cant_move]
    end
    redirect_to(manager_pages_path(:subdomain=>@subdomain)) and return
  end
  
  def down
    @page= Page.find_by_zip(params[:id])
    if @page.move_possible?(@page.right_sibling)                    # Если возможно переместить вниз
      @page.move_right                                              # Перемещаем
      flash[:notice] = Messages::NestedSet[:element][:down]
      redirect_to(manager_pages_path(:subdomain=>@subdomain)) and return
    else
      flash[:notice] = Messages::NestedSet[:element][:cant_be_move]
      redirect_to(manager_pages_path(:subdomain=>@subdomain)) and return
    end
  end

  def destroy
    @page= Page.find_by_zip(params[:id])
    if @page.children.count.zero?
      @page.destroy
      flash[:notice]= Messages::NestedSet[:element][:deleted]
    else
      flash[:notice]= Messages::NestedSet[:element][:has_children]
    end
    redirect_to(manager_pages_path(:subdomain=>@subdomain)) and return
  end
  
  protected

  def access_to_controller_action_required
    (access_denied and return) if current_user.has_personal_block?(controller_name, action_name)
    (access_denied and return) if current_user.has_group_block?(controller_name, action_name)
    
    return true if current_user.has_personal_access?(controller_name, action_name)
    return true if current_user.has_group_access?(controller_name, action_name)
    
    (access_denied and return) unless current_user.has_role_policy?(controller_name, action_name)
  end

  def page_resourсe_access_required
    # Поиск ресурса
    @page= Page.find_by_zip(params[:id])
    (access_denied and return) unless @page

    # Есть персональные или групповые блокировки к ресурсу
    (access_denied and return) if current_user.has_personal_resource_block_for?(@page, controller_name, action_name)
    (access_denied and return) if current_user.has_group_resource_block_for?(@page, controller_name, action_name)
    
    # Есть персональные или групповые разрешения к ресурсу (они выше по приоритету, чем общие блокировки)
    return true if current_user.has_personal_resource_access_for?(@page, controller_name, action_name)
    return true if current_user.has_group_resource_access_for?(@page, controller_name, action_name)
    
    # Есть персональные или групповые блокировки
    (access_denied and return) if current_user.has_personal_block?(controller_name, action_name)
    (access_denied and return) if current_user.has_group_block?(controller_name, action_name)
    
    # Есть персональные или групповые разрешения
    return true if current_user.has_personal_access?(controller_name, action_name)
    return true if current_user.has_group_access?(controller_name, action_name)
    
    # Пользователь - владелец объекта и имеет соответствующие ролевые политики
    (access_denied and return) unless current_user.is_owner_of?(@page) && current_user.has_role_policy?(controller_name, action_name)
  end
end