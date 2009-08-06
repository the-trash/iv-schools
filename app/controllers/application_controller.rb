# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Be sure to include AuthenticationSystem in Application Controller instead
  # Система авторизации
  include AuthenticatedSystem
  
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  layout 'application'
  
  before_filter :system_init    # Инициализация системных переменных
  before_filter :find_subdomain # Определить поддомен в котором мы находимся
  before_filter :find_user      # Определить пользователя системы, к которому мы пытаемся получить доступ (первый уровень поиска)
  #before_filter :set_user_language # i18n интернационализация
  
  protected

  def system_init 
    # Инициализировать флеш массив с системными уведомлениями
    flash[:system_warnings]= []
  end

  #def set_user_language
  #  I18n.locale = current_user.language if logged_in?
  #end
  
  #-------------------------------------------------------------------------------------
  #> Я - НЕ зарегистрированный пользователь
  # перехожу по ссылке без поддомена или user_id
  # При этом просматриваемый пользователь @user - User.find:first
  #> Я - НЕ зарегистрированный пользователь
  # перехожу по ссылке с поддоменом other_user, но без user_id
  # При этом просматриваемый пользователь @user - other_user
  #> Я - НЕ зарегистрированный пользователь
  # перехожу по ссылке без поддомена, но c user_id = other_user
  # При этом просматриваемый пользователь @user - other_user
  #> Я - НЕ зарегистрированный пользователь
  # перехожу по ссылке с поддоменом other_user, и c user_id = other_other_user
  # При этом просматриваемый пользователь @user - other_other_user
  #-------------------------------------------------------------------------------------
  #> Я - зарегистрированный пользователь current_user
  # перехожу по ссылке без поддомена или user_id
  # При этом просматриваемый пользователь @user - должен быть я
  #> Я - зарегистрированный пользователь current_user
  # перехожу по ссылке с поддоменом other_user, но без user_id
  # При этом просматриваемый пользователь @user - должен быть other_user
  #> Я - зарегистрированный пользователь current_user
  # перехожу по ссылке без поддомена, но c user_id = other_user
  # При этом просматриваемый пользователь @user - должен быть other_user
  #> Я - зарегистрированный пользователь current_user
  # перехожу по ссылке с поддоменом other_user, и c user_id = other_other_user
  # При этом просматриваемый пользователь @user - должен быть other_other_user
  #-------------------------------------------------------------------------------------
  
  # Если есть существующий поддомен - то @user - это поддомен
  # Определить поддомен в котором мы находимся
  def find_subdomain
    # По умолчанию - поддомен отсутствует
    # По умолчанию - просматриваемый пользователь - первый, который есть в системе
    # (должен быть администаратор)
    @subdomain= false
    
    # если мы зарегистрированы в системе, то по умолчанию, просматриваемый пользователь - это мы
    # например /pages/index ведет на просмотр нашего дерева страниц,
    # а для не зарегистрированного пользователя /pages/index ведет на центральное дерево страниц портала
    @user = current_user ? current_user : User.find(:first)
    
    if current_subdomain
      # поискать приставку www
      # вернуть чистое имя поддомена
      # По найденной приставке - ищем пользователя, если такового нет, то
      # то, нужно выдать ошибку - такой раздел сайта не существует
      # Если указанного поддомена не существует, то генерируем уведомление
      # Возвращаем в качестве пользователя первого пользователя системы
      
      # Просматриваем ресурсы
      # Или первого в системе пользователя, или тот, которого нашли по поддомену
      match= current_subdomain.match(/^www.(.+)/)
      @subdomain= match.nil? ? current_subdomain : match[1]
      user= User.find_by_login(@subdomain)
      unless user
        flash[:system_warnings].push(Site::DOMAIN_DOES_NOT_EXIST)
        @subdomain= false
      end
      @user= user ? user : @user
    end
  end
  
  # Если есть существующий пользователь с user_id - то @user - это пользователь с user_id
  def find_user    
    # Схема работы:
    # Если пользователь не найден по поддомену
    # Проверяем параметр params[:user_id] - если он есть и соответствует abcd345efg, то ищем по login
    # Если соответствует 12345456, то ищем по id
    
    # params[:user_id] - для сложносоставных маршрутов, для простых марщрутов - id (проверяем на низких уровнях контроллера)
    # Там сделаю mixin для контроллеров с переопределением def find_user
    if params[:user_id]
      if params[:user_id].match(Format::NUMBERS) # id cовпал с целым числом
        user= User.find_by_id(params[:user_id])
      elsif params[:user_id].match(Format::LOGIN) # id cовпал с login        
        user= User.find_by_login(params[:user_id])
      end #params[:user_id].match
      user ? nil : flash[:system_warnings].push(Site::SECTION_NOT_FOUND+params[:user_id].to_s)
    end #params[:user_id]
    # Просматриваем ресурсы
    # Пользователя ранее найденного по поддомену или того, которого нашли по id || login || zip
    @user= user ? user : @user
  end

  # Функция, необходимая для формирования базового меню-навигации
  # Отображаются только корневые разделы карты сайта
  def navigation_menu_init
    # Должен существовать хотя бы один пользователь
    (render :text=>t('system.have_no_users') and return) unless @user
    # Должен существовать хотя бы один пользователь
    @root_pages= Page.find_all_by_user_id_and_parent_id(@user.id, nil, :order=>"lft ASC")
  end
    
  # Перенаправление взамен стандартному
  # Используется в приложении
  def redirect_back_or(path)
    redirect_to :back
    rescue ActionController::RedirectBackError
    redirect_to path
  end
end
