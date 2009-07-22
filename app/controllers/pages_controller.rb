class PagesController < ApplicationController  
  # Проверка на то, что пользователь авторизован
  before_filter :login_required, :except=>[:index, :show]
    
  # Формирование данных для отображения базового меню-навигации
  before_filter :navigation_menu_init, :except=>[:show]
  
  # Требование на наличие прав редактирования страниц данного подомена
  before_filter :page_manager_required, :except=>[:index, :show]
    
  # Центральная страница раздела Страницы
  # Карта сайта (дерево страниц сайта)
  def index
    # Выбрать дерево страниц, только те поля, которые учавствуют отображении
    @pages_tree= Page.find_all_by_user_id(@user.id, :select=>'id, title, zip, parent_id', :order=>"lft ASC")
    @tester= current_user
  end

  # Показать страницу
  def show
    @page= Page.find_by_zip params[:id]
    @parents= @page.self_and_ancestors if @page
    @siblings= @page.children if @page
  end
    
  # Защищенная часть контроллера
  # Только для администратора портала
  # Администраторов верхних уровней - ключ доступа [administrators::pages::manager]
  # Редактора сайта (владелец поддомена + [site_owner::pages::manager])
  # Владельцев ключей [administrators::pages::manager], [site_owner::pages::manager] для данного поддомена

  #-------------------------------------------------------------------------------------------------------
  # Создание новой страницы
  #-------------------------------------------------------------------------------------------------------
  def new
    @parent= nil
    @parent= Page.find_by_zip(params[:parent_id]) if params[:parent_id]
    @page= Page.new
  end
  
  # POST /pages
  # К созданию страниц допущены центральные администраторы
  # Владелец домена, с соответствующими правами
  # Пользователи обладающие првом создавать страницы в данном поддомене
  # (Обладающие правами управления pages::create по отношению к объекту пользователя)
  def create
    # Создать новую страницу и установить в ней данные
    @page= Page.new(params[:page])
    
    #render :text=>params.inspect and return
    # Найти родителя
    # Сгенерировать zip
    # Определить владельца страницы
      # Страница должна принадлежать поддомену в котором она создается
      # Т.е. фактически - пользователю, владельцу домена
      # В системе это у меня переменная @user, которая определена всегда
      # И отражает пользователя - поддомен которого мы просматриваем
      # Если текущий пользователь и @user - одно лицо - устанавливает user_id=@user.id
      # Иначе, проверить права доступа текущего пользователя к функции создания странц
      # В чужом поддомене. administrators::pages::management или персональная политика pages::management
    
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
        # Если определен родитель - новую страницу сделать дочерней
        @page.move_to_child_of(@parent) if @parent
        
        flash[:notice] = Messages::Pages[:created]
        format.html { redirect_to(edit_page_path(@page.zip)) }
      else
        format.html { render :action => "new" }
      end
    end
  end# create
  #-------------------------------------------------------------------------------------------------------
  # ~Создание новой страницы
  #-------------------------------------------------------------------------------------------------------
  
  #-------------------------------------------------------------------------------------------------------
  # Редактирование страницы
  #-------------------------------------------------------------------------------------------------------
  # К редактированию страниц допущены центральные администраторы
  # Владелец домена, с соответствующими правами
  # Пользователи обладающие првом редактировать данную страницу
  # (Обладающие правом pages::увше по отношению к объекту страницы)
  def edit
    @page= Page.find_by_zip(params[:id])
  end
  
  # PUT /pages/2343-5674-3345
  def update
    @page = Page.find_by_zip(params[:id])
    #render :text=>params.inspect and return
    
    respond_to do |format|
      if @page.update_attributes(params[:page])
        flash[:notice] = Messages::Pages[:updated]
        format.html { redirect_back_or(manager_pages_path(:subdomain=>@subdomain)) }
      else
        format.html { render :action => "edit" }
      end
    end
  end# update
  #-------------------------------------------------------------------------------------------------------
  # ~Редактирование страницы
  #-------------------------------------------------------------------------------------------------------

  # Карта сайта редактора
  def manager
    @pages_tree= Page.find_all_by_user_id(@user.id, :order=>"lft ASC")
  end# admin
  
  # Переместить страницу вниз
  def down
    @page= Page.find_by_zip(params[:id])
    # Если возможно переместить вниз
    if @page.move_possible?(@page.right_sibling)
      # Перемещаем
      @page.move_right
      flash[:notice] = Messages::NestedSet[:element][:down]
      redirect_to(manager_pages_path(:subdomain=>@subdomain)) and return
    else
      flash[:notice] = Messages::NestedSet[:element][:cant_be_move]
      redirect_to(manager_pages_path(:subdomain=>@subdomain)) and return
    end
  end# down
  
  # Переместить страницу вверх
  def up
    @page= Page.find_by_zip(params[:id])
    # Если возможно переместить вверх
    if @page.move_possible?(@page.left_sibling)
      # Перемещаем
      @page.move_left
      flash[:notice] = Messages::NestedSet[:element][:up]
    else
      flash[:notice] = Messages::NestedSet[:element][:cant_move]
    end
    
    redirect_to(manager_pages_path(:subdomain=>@subdomain)) and return
  end# up
  
  # Удалить страницу
  def destroy
    @page= Page.find_by_zip(params[:id])
    if @page.children.count.zero?
      @page.destroy
      flash[:notice] = Messages::NestedSet[:element][:deleted]
    else
      flash[:notice] = Messages::NestedSet[:element][:has_children]
    end
    redirect_to(manager_pages_path(:subdomain=>@subdomain)) and return
  end# destroy
  
  protected
  
  # Требование на наличие у пользователя прав на редактирование дерева страниц
  def page_manager_required
    # Если владелец поддомена/раздела
    if current_user == @user
      # Если запись существует, то вернуть ее значение, иначе nil
      # Возможно мы временно отключили данное право, или временно включили для данного пользователя
      return current_user.has_personal_access?(:pages, :manager) unless current_user.has_personal_access?(:pages, :manager).nil?
      # Если запись существует, то вернуть ее значение, иначе nil
      # Возможно мы временно отключили данное право, или временно включили для данной группы
      return current_user.has_group_policy?(:pages, :manager) unless current_user.has_group_policy?(:pages, :manager).nil?
      # Если есть нужная политика а хеше роли
      return current_user.has_role_policy?(:pages, :manager)
    end

    flash[:notice] = Messages::Policies[:have_no_policy]
    access_denied
    return
    
    # Сначала, наверное, нужно проверять самые конкретизированные права на доступ
    # Поскольку они перекрывают права более общие
    # Так если установлен доступ к конкретному объекту для конкретного пользователя,
    # то безразлично, есть ли персональный набор прав или групповой набор - доступ все равно будет
    
    # Проверка на доступ __персоны__ к конкретному объекту - ресурсное владение |Имеет временнОе и количественное ограничение|
    # Проверка на персональный доступ - к ресурсу не привязано - доступ __персоны__ к работе с группой объектов |Имеет временнОе и количественное ограничение|
    # Групповой доступ - к ресурсам не привязан - доступ группы к работе с группой объектов |ВременнЫх и количественных ограничений не имеет|
    
    # Если установлено ресурсное правило - вернем его значение
    # resource_policy= current_user.has_resource_policy(@page, :page, :manage)
    # resource_policy ? (return resource_policy) : false
    # 
    # Если установлено персональное правило - вернем его значение
    # personal_policy= current_user.has_personal_access(:page, :manage)
    # personal_policy ? (return personal_policy) : false
    # 
    # Если установлено групповое правило
    # group_policy= current_user.has_group_policy_policy(:page, :manage)
    # group_policy ? (return group_policy) : false
    
    # current_user.has_role_policy?(:global, :pages_manager)                               Глобальный редактор страниц
    # current_user.has_group_policy?(:global, :pages_manager)                         Глобальный редактор страниц, через группу
    # current_user.has_personal_access?(:global, :pages_manager)                      Глобальный редактор страниц, через личную правовую настройку
    # current_user.has_group_resource_policy_for?(@user,:global, :pages_manager)      Глобальный редактор страниц, через группу и только для данного объекта
    # current_user.has_personal_resource_policy_for?(@user,:global, :pages_manager)   Глобальный редактор страниц, через личную правовую настройку и только для данного объекта

    # current_user.has_role_policy?(:pages, :manager) && current_user==@user               Владелец страниц обладающий правом
    
    # current_user.has_group_resource_policy_for?(@user,    :pages, :manager)         Может иметь доступ к данному правилу для данного пользователя через группу
    # current_user.has_personal_resource_policy_for?(@user, :pages, :manager)         Может иметь доступ к данному правилу для данного пользователя через личную правовую настройку
    
    # Если это владелец домена
    unless current_user.id == @user.id
      if current_user.has_role_policy?(:pages, :manager)
        # Проверим - обладает ли он правами управления страниц на своем сайте
        # Если обладает - проверим, нет ли временного ограничения его прав
        flash[:notice] = 'has policy'
      else
        # Если не обладает правами, то проверим
        # обладает ли он правами на временное управление страницами
        flash[:notice] = 'has no policy'
      end
    else
      # Если это не владелец домена
      # Проверим, обладет ли пользователь временным правом на управление страниц
      # Привзка к объекту @user 
      flash[:notice] = 'Policy alert!'
    end# if current_user.id == @user.id
  end
end
