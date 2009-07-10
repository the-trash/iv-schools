require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User do

  # Исполняется однажды перед всеми тестами
  # Установить пример валидных и не валидных данных
  before(:all) do  
    @valid_attributes = {
      :login=>'admin123',
      :email=>'admin@admin.ru',
      :password=>'admin@admin.ru',
      :password_confirmation=>'admin@admin.ru',
      :name=>'Привет!'
    }
    
    @invalid_attributes = {
      :login=>'',
      :email=>'secondadmin@admin.ru',
      :password=>'admin@admin.ru',
      :password_confirmation=>'admin@admin.ru',
      :name=>'Привет!2'
    }
  end

  # Исполняется перед каждым тестом
  before(:each) do
  end

  # Создание пользователя
  it "user create" do
    User.create!(@valid_attributes)
  end
  
  # Ошибка при пустом логине
  it "login incorrect" do
    u= User.new @invalid_attributes
    u.should have(2).error_on(:login)
  end
  
  # Пользователь должен быть уникальным
  it "user must be uniq" do
    u1= User.new @valid_attributes
    u1.save
    
    u2= User.new @valid_attributes
    u2.save.should be_false
  end
  
  # Пользователь имеет 3 персональные политики 
  it "have 3 personal policy" do
    user= User.find:first
    
  end
  
  def my_helper_method
    # А так можно оформить любой необходимый хелпер
    # Вобщем любую функцию, которая может сократить тест
  end
  
end
