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
end
