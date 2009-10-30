module Paperclip
  class FirstProcessor < Processor

    def initialize(file, options = {}, attachment = nil)    
      super
      @file                = file
      @current_format      = File.extname(@file.path)
      @basename            = File.basename(@file.path, @current_format)
    end

    def make
      @file.pos = 0                                               # в основном файле перевести каретку на начало, если ее уже сместил другой процессор 
      src = @file                                                 # открыть источник
      dst = Tempfile.new([@basename, @format].compact.join("."))  # открыть цель
      dst.binmode                                                 # перевод цели в бинарный режим (не существенно)
    end # make
  end
end

class StorageFile < ActiveRecord::Base  
  belongs_to :user
  belongs_to :storage_section
    
  has_attached_file :file,
                    :styles => {
                      :micro=>'50x50#',
                      :mini=>'100x100#',
                      :small=>'150x150#'
                    },
                    :convert_options => { :all => "-strip" },
                    :url => Project::FILE_URL,
                    :default_url=>Project::FILE_DEFAULT,
                    :processors => lambda { |a| a.is_image? ? [ :thumbnail ] : [:first_processor ] }

  def is_image?
    [ 'image/jpeg',
      'image/gif',
      'image/png',
      'image/pjpeg',
      'image/x-png',
      'image/jpg'
    ].include?(file.content_type)
  end
                                        
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
