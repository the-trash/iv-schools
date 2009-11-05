
class StorageFile < ActiveRecord::Base  
  belongs_to :user
  belongs_to :storage_section
    
  has_attached_file :file,
                    :styles => {
                      :small=> '100x100#',
                      :mini=>  '50x50#'
                    },
                    :convert_options => { :all => "-strip" },
                    :url => Project::FILE_URL,
                    :default_url=>Project::FILE_DEFAULT,
                    :processors => lambda { |a| a.is_image? ? [ :thumbnail ] : [:empty_processor ] }

  def is_image?
    #['image/gif','image/jpeg','image/jpg','image/pjpeg','image/png','image/x-png','image/bmp']
    ['.gif','.jpeg','.jpg','.pjpeg','.png','.bmp'].include?(File.extname(file_file_name))
  end
  
  def is_doc?
    #['application/msword', 'application/x-doc'].include?(file.content_type)  
    ['.doc', '.docx'].include?(File.extname(file_file_name))
  end
  
  def is_txt?
    ['text/plain'].include?(file.content_type)    
  end
  
  def is_ppt?
    ['application/vnd.ms-powerpoint', 'application/x-ppt'].include?(file.content_type)
  end
  
  def is_xls?
    ['application/vnd.ms-excel'].include?(file.content_type)
  end
  
  def is_pdf?
    ['application/pdf'].include?(file.content_type)
  end  
  
  def is_psd?
    #['image/photoshop','image/x-photoshop','image/psd','application/photoshop','application/psd','zz-application/zz-winassoc-psd'].include?(file.content_type)
    ['.psd'].include?(File.extname(file_file_name))
  end
  
  def is_media?
    ['video/x-msvideo','audio/wav','application/x-wmf','video/mpeg','audio/mpeg','audio/mp3'].include?(file.content_type)
  end
  
  def is_arch?
    ['.zip','.rar','.gz','.tar'].include?(File.extname(file_file_name))
    #['application/x-zip','application/zip','application/x-zip-compressed','application/x-rar','application/rar','application/x-rar-compressed','application/x-tar'].include?(file.content_type)
  end
                                  
  validates_presence_of :name, :message=>"Необходимо указать имя файла"

  #validates_attachment_size :file,
  #                          :in => 1.kilobytes..1.megabytes,
  #                          :message=>'Размер файла должен быть более 1 Килобайта и менее 1 Мегабайта'
    
  # ------------------------------------------------------------------  
  # Создать данному объекту zip код
  before_create :create_zip
  def create_zip
    # Если zip уже установлен ранее
    return unless (zip.nil? || zip.empty?)
    zip_code= "#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}"
    while self.class.to_s.camelize.constantize.find_by_zip(zip_code)
      zip_code= "#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}"
    end
    self.zip= zip_code
  end
end