class Page < ActiveRecord::Base  
  # Действуй как дерево, привязанное к владельцу (пользователю)
  acts_as_nested_set :scope=>:user
  belongs_to :user
  
  validates_presence_of :user_id,      :message=>"Не определен идентификатор владельца страницы"
  validates_presence_of :zip,         :message=>"Не определен zip-идентификатор страницы"

  validates_presence_of :author,      :message=>"Системное поле: Автор &mdash; не должно оставаться пустым"
  validates_presence_of :keywords,    :message=>"Системное поле: Ключевые слова &mdash; не должно оставаться пустым"
  validates_presence_of :description, :message=>"Системное поле: Описание &mdash; не должно оставаться пустым"
  validates_presence_of :copyright,   :message=>"Системное поле: Авторское право &mdash; не должно оставаться пустым"
  validates_presence_of :title,       :message=>"У страницы должен быть заголовок"
  
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
