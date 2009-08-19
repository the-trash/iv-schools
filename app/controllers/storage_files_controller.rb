class StorageFilesController < ApplicationController

  def create
    @storage_section = StorageSection.find_by_zip(params[:storage_section_zip])
    @storage_file= @storage_section.storage_files.new(params[:storage_file])
    @storage_file.user_id= @user.id
    @storage_file.file= params[:storage_file][:file]

    zip= zip_for_model('StorageFile')
    @storage_file.zip= zip
    
    extension = File.extname(@storage_file.file_file_name)
    @storage_file.file.instance_write(:file_name, "#{zip}#{extension}")
    
    respond_to do |format|
      if @storage_file.save
        flash[:notice] = 'created'
        format.html { redirect_to(storage_section_url(@storage_section.zip)) }
      else
        flash[:notice] = 'error'
        format.html { redirect_to(storage_section_url(@storage_section.zip)) }
      end
    end
  end
  
  protected
  
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

  def storage_section_resourñe_access_required
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
