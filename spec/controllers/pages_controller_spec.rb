require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PagesController do
  #before(:all) do
  #end
  
  #before(:each) do
  #end
  
###################################################################################################
# PagesController Basic Tests
###################################################################################################

  describe "PagesController Basic Tests" do  
    #Контроллер должен быть контроллером PagesController
    it "should use PagesController" do
      controller.should be_an_instance_of(PagesController)
    end
  
    # Проверить наличие before фильтров
    it "11:00 14.07.2009, should be successful" do
      # должен существовать фильтр с такими опциями
      controller.before_filters.should include(:login_required)
      controller.before_filter(:login_required).should have_options(:except=>[:index, :show])
      
      # должен существовать фильтр с такими опциями
      controller.before_filters.should include(:page_manager_required)
      controller.before_filter(:page_manager_required).should have_options(:except=>[:index, :show])
      
      # должен существовать фильтр с такими опциями
      controller.before_filters.should include(:navigation_menu_init)
      controller.before_filter(:navigation_menu_init).should have_options(:except=>[:show])
    end#11:00 14.07.2009
      
    # Проверить роуты для контроллера pages
    it "10:35 14.07.2009, should be successful" do
      route_for(:controller => 'pages', :action => 'index').should == '/pages/'
      route_for(:controller => 'pages', :action => 'show', :id=>'1').should == '/pages/show/1'
    end#10:35 14.07.2009
    
    # Проверить формирование путей контроллера pages
    it "10:46 14.07.2009, should be successful" do      
      params_from(:get, "/pages/show/2").should == {:controller => 'pages', :action => 'show', :id=>'2'}
      params_from(:get, "/pages/show/17").should == {:controller => 'pages', :action => 'show', :id=>'17'}
    end#10:46 14.07.2009    
  end# describe "PagesController Basic Tests"
  
###################################################################################################
# PagesController Anomaly Tests
###################################################################################################

  describe "PagesController Anomaly Tests" do 
    # Нет ни одного пользователя
    # Будет возвращено сообщение и успешный ответ
    it "10:37 14.07.2009, should be successful" do
      get('index')
      response.should have_text(Messages::System[:have_no_users])
      response.should be_success
    end#10:37 14.07.2009
  end# describe "PagesController Anomaly Tests"
  
###################################################################################################
# PagesController Methods Tests
###################################################################################################
  
  describe "PagesController Methods Tests" do  
    describe "GET index" do
      
      before(:each) do
        admin= Factory.create(:admin)
        ivanov= Factory.create(:ivanov)
        petrov= Factory.create(:petrov)
        @user= {:admin=>admin, :ivanov=>ivanov, :petrov=>petrov}
      end
    
      # Один пользователь просматривает дерево страниц другого (админа)
      it "11:40 14.07.2009, should be successful" do
        pages_count= 3
        # Создать страницы для пользователя
        create_pages_for(@user[:admin], pages_count)
        # Подменить реальный метод контроллера и заставить его возвращать нужный результат
        controller.stub!(:current_user).and_return(@user[:ivanov])
        # Выполнить действие контроллера
        get('index')
        # Ожидаемые результаты
        assigns[:pages_tree].should have(pages_count).items
        response.should render_template('index')    
        response.should be_success
      end#11:40 14.07.2009

      # Иванов просматривает дерево страниц Петрова
      # Один пользователь просматривает дерево страниц другого (админа)
      it "14:28 14.07.2009, should be successful" do
        # Подменить реальный метод контроллера и заставить его возвращать нужный результат
        # Текущий поддомен
        controller.stub!(:current_subdomain).and_return(@user[:petrov].login)
        # Текущий Пользователь
        controller.stub!(:current_user).and_return(@user[:ivanov])
        
        pages_count= 3
        # Создать страницы для пользователя
        create_pages_for(@user[:petrov], pages_count)

        @method = :get
        @action = :index
        @params = {}

        send @method, @action, @params
              
        # Ожидаемые результаты
        assigns[:pages_tree].should have(pages_count).items
        response.should render_template('index') 
        response.should be_success
      end#14:28 14.07.2009
    end#describe GET 'index'
    
    describe "GET manager" do
      before(:each) do
        admin= Factory.create(:admin)
        ivanov= Factory.create(:ivanov)
        petrov= Factory.create(:petrov)
        @user= {:admin=>admin, :ivanov=>ivanov, :petrov=>petrov}
      end
      
      #  Доступ к редактированию страниц без авторизации не возможен
      #  Должно переадресовать на стр. регистрации
      it "21:05 14.07.2009, should be successful" do      
        @method = :get
        @action = :manager
        @params = {}

        send @method, @action, @params
        
        response.should_not be_success
        response.should redirect_to(new_session_path)
      end# 21:05 14.07.2009
      
      #  Пользователи :admin, :ivanov
      #  Иванов хочет просмотреть страницу с редактированием страниц
      #  Иванов зарегистрирован, но не имеет прав на это
      it "21:05 14.07.2009, should be successful" do
        # Подменить реальный метод контроллера и заставить его возвращать нужный результат
        controller.stub!(:current_user).and_return(@user[:petrov])
        
        @method = :get
        @action = :manager
        @params = {}

        send @method, @action, @params
        
        # Отправим Иванова на страницу регистрации.. пусть подумает о своем поведении =)
        response.should_not be_success
        response.should redirect_to(new_session_path)
        flash[:notice].should have_text(Messages::Policies[:have_no_policy])
      end# 21:05 14.07.2009
      
      #  Пользователи :admin, :admin
      #  :admin хочет просмотреть страницу с редактированием страниц
      #  :admin зарегистрирован, и имеет прав на это, т.к доступ к своим ресурсам
      #  и обладает правом
      it "21:05 14.07.2009, should be successful" do
        user= @user[:admin]
        page_manager_role= Factory.create(:page_manager_role)
        # Установим роль
        user.update_attribute(:role_id, page_manager_role.id)
        # Подменить реальный метод контроллера и заставить его возвращать нужный результат
        controller.stub!(:current_user).and_return(user)
        
        @method = :get
        @action = :manager
        @params = {}

        send @method, @action, @params
        response.should be_success
        response.should render_template(@action)
      end# 21:05 14.07.2009
      
    end#describe GET 'manager'
  end#describe "PagesController Methods Tests"

###################################################################################################
# Testing Helpers
###################################################################################################
  
  # Создать 2 тестовых пользователя
  def make2users(name0, name1)
      u0= Factory.create(name0)
      u1= Factory.create(name1)
      {name0=>u0, name1=>u1}
  end#2users
  
  # Создать Страницы для пользователя
  def create_pages_for(user, count)
    count.times do
      zip= "#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}"
      while Page.find_by_zip(zip)
        zip= "#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}"
      end
      # Создать страницу
      page= user.pages.new(
        :zip=>zip,
        :author=>Faker::Name.name,
        :keywords=>Faker::Lorem.sentence(2),
        :description=>Faker::Lorem.sentence(2),
        :copyright=>Faker::Name.name,
        :title=>"Тестовая страница: #{Faker::Lorem.sentence(3)}",
        :annotation=>Faker::Lorem.sentence(30),
        :content=>Faker::Lorem.paragraphs(50)
      )
      page.save # Сохранить страницу
    end #count.times    
  end#create_pages_for(user)
  
###################################################################################################
# Testing Helpers
###################################################################################################
end