class PagesController < ApplicationController
  # Формирование данных для отображения базового меню-навигации
  before_filter :navigation_menu_init, :except=>[:show]
  
  def map
    @pages_tree= Page.find_all_by_user_id(@user.id, :order=>"lft ASC")
  end

  def show
    @page= Page.find_by_id params[:id]
    @parents= @page.self_and_ancestors
    @siblings= @page.children
  end
end
