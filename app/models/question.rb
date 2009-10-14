class Question < ActiveRecord::Base
  belongs_to :user
  before_save :create_zip
  
  # ------------------------------------------------------------------
  # Машина состояний state
  state_machine :state, :initial => :new_question do
    # Чтание нового сообщения
    event :reading do
      # Новый вопрос просматривается и изменяет свое состояние
      transition :new_question => :seen
    end
    
    # Блокировка сообщения
    event :blocking do
      # Из всех состояний кроме delete должен перейти в это
      transition all - :deleted => :block
    end
    
    # Разблокировка сообщения
    event :unblocking do
      # Из состояния бока перейти в состояние просмотренного сообщения
      transition :block => :seen
    end
    
    # Удаление сообщения
    event :deleting do
      # Из всех состояний должен перейти в это
      transition all => :deleted
    end
  end
  
  # ------------------------------------------------------------------  
  # Создать данному объекту zip код
  def create_zip
    zip_code= "#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}"
    while self.class.to_s.camelize.constantize.find_by_zip(zip_code)
      zip_code= "#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}"
    end
    self.zip= zip_code
  end
end
