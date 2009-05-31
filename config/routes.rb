ActionController::Routing::Routes.draw do |map|
  map.resources :users
  map.resource :session

  map.signup '/signup', :controller => 'users', :action => 'new'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  
  map.root :controller => 'users', :action => 'index'

  #------------------------------------------------------------------------------------#
  #- Парная связка, которая должна вести к одним и тем же обработчикам
  #- Первый фрагмент - через идентификатор пользователя
  #- Второй фрагмент - напрямую через поддомен или объект текущего пользователя
  #------------------------------------------------------------------------------------#
  # Доступ через пользователя
  map.resources :users do |user|
    user.resources :albums do |album|   #/users/:user_id/albums, /users/:user_id/albums/new
      album.resources :images,
        :member=>{ :need_id=>:get },    #/users/:user_id/albums/:album_id/images/:id/need_ids
        :collection=>{ :no_ids=>:get }  #/users/:user_id/albums/:album_id/images/no_ids
    end #:albums
  end #:users
  
  # Доступ напрямую через поддомен
  map.resources :albums do |album|   #/albums, /albums/new
    album.resources :images,
      :member=>{ :need_id=>:get },    #/albums/:album_id/images/:id/need_ids
      :collection=>{ :no_ids=>:get }  #/albums/:album_id/images/no_ids
  end #:albums
  
  #------------------------------------------------------------------------------------#
  #------------------------------------------------------------------------------------#
  #------------------------------------------------------------------------------------#

  #------------------------------------------------------------------------------------#
  # Администраторский роутер - работает с app/controllers/admins, app/view/admins
  #------------------------------------------------------------------------------------#
  map.namespace(:admins) do |admin|
    # /admins/users/new, /admins/users/:id/edit
    admin.resources :users,
    :member=>{:change_role => :post} # /admins/users/:id/change_role
    
     
    # /admins/roles/new
    # /admins/roles/:id/edit
    admin.resources :roles,
    :member=>{
      :new_role_section=>:post,                   # /admins/roles/:id/new_role_section
      :new_role_rule=>:post                       # /admins/roles/:id/new_role_rule
    } do |role|
      # /admins/roles/:role_id/sections/new
      #/admins/roles/:role_id/sections/:id/edit
      role.resources :sections,
        :controller=>'role_section',               
        :member=>{
          :new_rule=>:get,                           # /admins/roles/:role_id/sections/:id/new_rule
          :delete_rule=>:delete                      # /admins/roles/:role_id/sections/:id/delete_rule/?name=some_name
        }
    end
  end #:admin
  #------------------------------------------------------------------------------------#
  # Стандартная маршрутизация
  #------------------------------------------------------------------------------------#
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
