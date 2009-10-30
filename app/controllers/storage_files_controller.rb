class StorageFilesController < ApplicationController

  before_filter :login_required
  #before_filter :access_to_controller_action_required,      :only => [:create, :destroy]
  #before_filter :storage_section_resourсe_access_required,  :only => [:create, :destroy]
  before_filter :find_file,  :only => [:destroy]
  
  def create
    if params[:storage_file] && params[:storage_file][:file]
      @storage_section = StorageSection.find_by_zip(params[:storage_section_zip])
      @storage_file= @storage_section.storage_files.new(params[:storage_file])
      @storage_file.user_id= @user.id
    
      @storage_file.file= params[:storage_file][:file]

      zip= zip_for_model('StorageFile')
      @storage_file.zip= zip
    
      extension = File.extname(@storage_file.file_file_name)
      @storage_file.file.instance_write(:file_name, "#{zip}#{extension}")
      respond_to do |format|
        if @storage_file.save!
          flash[:notice] = 'Успешно загружено'
          render :text=>@storage_file.to_yaml and return
          format.html { redirect_to(storage_section_url(@storage_section.zip)) }
        else
          render :text=>@storage_file.to_yaml and return
          @storage_section_files= StorageFile.paginate_all_by_storage_section_id(@storage_section.id,
                                 :order=>"created_at DESC", #ASC, DESC
                                 :page => params[:page],
                                 :per_page=>20
                                 )
          format.html { render  :template => "storage_sections/show" }
        end
      end
    else
      flash[:notice] = 'Кажется, Вы забыли указать файл'
      redirect_to(storage_section_url(params[:storage_section_zip]))
    end# if params[:storage_file]
  end
  
  def destroy
    @file.destroy
    flash[:notice] = 'Кажется, Вы удалили этот файл навсегда'
    redirect_back_or(storage_sections_url)
  end
  
  protected
  
  def find_file
    @file= StorageFile.find_by_zip(params[:id])
    access_denied and return unless @file
  end
  
  def find_storage_section
    @storage_section= StorageSection.find_by_zip(params[:id])
    access_denied and return unless @storage_section
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

  def storage_section_resourсe_access_required
      access_denied if current_user.has_complex_resource_block_for?(@storage_section, :administrator, controller_name)
      return true   if current_user.has_complex_resource_access_for?(@storage_section, :administrator, controller_name)
      return true   if current_user.has_role_policy?(:administrator, controller_name)
      access_denied if current_user.has_complex_block?(:administrator, controller_name)
      return true   if current_user.has_complex_access?(:administrator, controller_name)
      access_denied if current_user.has_complex_resource_block_for?(@storage_section, controller_name, action_name)
      return true   if current_user.has_complex_resource_access_for?(@storage_section, controller_name, action_name)
      access_denied if current_user.has_complex_block?(controller_name, action_name)
      return true   if current_user.has_complex_access?(controller_name, action_name)
      return true   if current_user.has_role_policy?(controller_name, action_name) && current_user.is_owner_of?(@storage_section)
      access_denied
  end
  
end
