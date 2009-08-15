class StorageSectionsController < ApplicationController
  def index
    @storage_sections= StorageSection.find_all_by_user_id(@user.id)
    @storage_section= StorageSection.new
  end
  
  def show
    @storage_section= StorageSection.find_by_zip(params[:id])
    @storage_section_files= StorageFile.paginate_all_by_storage_section_id(@storage_section.id,
                           :order=>"created_at DESC", #ASC, DESC
                           :page => params[:page],
                           :per_page=>20
                           )
  end
  
  def create
    @storage_section= StorageSection.new(params[:storage_section])
    zip= zip_for_model('StorageSection')
    @storage_section.zip= zip
    @storage_section.user_id= @user.id 
    respond_to do |format|
      if @storage_section.save
        flash[:notice] = 'Раздел создан'
        format.html { redirect_to(storage_sections_path) }
      else
        flash[:notice] = 'Ошибка при создании раздела хранилища файлов'
        format.html { redirect_to(storage_sections_path) }
      end
    end
  end
end
