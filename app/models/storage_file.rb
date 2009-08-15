class StorageFile < ActiveRecord::Base
  belongs_to :user
  belongs_to :storage_section
  
  has_attached_file :file, :convert_options => {:all => "-strip"}, :url => Project::FILE_URL

  #validates_attachment_content_type :file,
  #                                  :content_type => ['image/jpg', 'image/jpeg', 'image/pjpeg', 'image/gif', 'image/png', 'image/x-png'],
  #                                  :message=>'Content_type_error'
                                    
  #validates_attachment_size :file,
  #                          :in => 1.kilobytes..2.megabytes,
  #                          :message=>'size_error'
end
