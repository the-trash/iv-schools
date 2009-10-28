class StorageFile < ActiveRecord::Base
  belongs_to :user
  belongs_to :storage_section
  
  has_attached_file :file, :convert_options => {:all => "-strip"}, :url => Project::FILE_URL
  validates_presence_of   :name, :message=>"Необходимо указать имя файла"
  validates_uniqueness_of :name, :case_sensitive => false, :message=>"Такое название файла уже используется где-то на сервере.<br />Измените название файла и загрузите еще раз"
  
  #validates_attachment_content_type :file,
  #                                  :content_type => ['image/jpg', 'image/jpeg', 'image/pjpeg', 'image/gif', 'image/png', 'image/x-png'],
  #                                  :message=>'Content_type_error'
                                    
  #validates_attachment_size :file,
  #                          :in => 1.kilobytes..2.megabytes,
  #                          :message=>'size_error'
  
  # ------------------------------------------------------------------  
  # Создать данному объекту zip код
  before_create :create_zip
  def create_zip
    zip_code= "#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}"
    while self.class.to_s.camelize.constantize.find_by_zip(zip_code)
      zip_code= "#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}"
    end
    self.zip= zip_code
  end
end
