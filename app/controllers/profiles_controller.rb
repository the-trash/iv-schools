class ProfilesController < ApplicationController

  before_filter :login_required
  before_filter :find_profile, :only=>[:update]

  def update
    @profile.update_attributes(params[:profile])
    flash[:notice]= 'Профайл успешно обновлен'
    redirect_to(profile_users_path(:subdomain=>@subdomain)) and return
  end
  
  def name
    @user= User.find_by_id(params[:id])
    @user.update_attribute(:name, params[:user][:name])
    flash[:notice]= 'Имя успешно обновлено'
    redirect_to(profile_users_path(:subdomain=>@subdomain)) and return
  end
  
  protected
  
  # Поиск ресурса
  def find_profile
    @profile= Profile.find_by_id(params[:id])
    access_denied and return unless @profile
  end
  
end
