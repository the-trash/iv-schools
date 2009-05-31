# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

# Рекурсивное объединение Хеш массивов
class Hash
  # Рекурсивно объединить 
  def recursive_merge!(hash= nil)
    return self unless hash.is_a?(Hash)
    base= self
    hash.each do |key, v|
      if base[key.to_sym].is_a?(Hash) && hash[key.to_sym].is_a?(Hash)
        base[key.to_sym]= base[key.to_sym].recursive_merge!(hash[key.to_sym])
      else
        base[key.to_sym]= hash[key.to_sym]
      end
    end
    base.to_hash
  end
  
  # Рекурсивно привести все значения к исходному состоянию
  def recursive_set_values_on_default!(default_value= false)
    base= self
    base.each do |key, v|
      if base[key.to_sym].is_a?(Hash)
        base[key.to_sym]= base[key.to_sym].recursive_set_values_on_default!(default_value)
      else
        base[key.to_sym]= default_value
      end
    end
  end
  
  # Рекурсивно объединить и установить в качестве значения указанный параметр default_value
  def recursive_merge_with_default!(hash= nil, default_value= true)
    return self unless hash.is_a?(Hash)
    base= self
    hash.each do |key, v|
      if base[key.to_sym].is_a?(Hash) && hash[key.to_sym].is_a?(Hash)
        base[key.to_sym]= base[key.to_sym].recursive_merge_with_default!(hash[key.to_sym], default_value)
      else
        base[key.to_sym]= default_value
      end
    end
    base.to_hash
  end
end

class ApplicationController < ActionController::Base
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  layout 'application'
  
  before_filter :system_init    # Инициализация системных переменных
  before_filter :find_subdomain # Определить поддомен в котором мы находимся
  before_filter :find_user      # Определить пользователя системы, к которому мы пытаемся получить доступ (первый уровень поиска)
  
  protected
  
  def system_init 
    # Инициализировать флеш массив с системными уведомлениями
    flash[:system_warnings]= []
  end
  
  # Определить поддомен в котором мы находимся
  def find_subdomain
    @subdomain= false
    @user = User.find :first
    if current_subdomain
      # поскать приставку www
      # вернуть чистое имя поддомена
      match= current_subdomain.match(/^www.(.+)/)
      @subdomain= match.nil? ? current_subdomain : match[1]
      # По найденной приставке - ищем пользователя, если такового нет, то
      # то, нужно выдать ошибку - такой раздел сайта не существует
      user= User.find_by_login(@subdomain)

      # Если указанного поддомена не существует, то генерируем уведомление
      # Возвращаем в качестве пользователя первого пользователя системы
      unless user
        flash[:system_warnings].push(Site::DOMAIN_DOES_NOT_EXIST)
        @subdomain= false
      end
      @user = user ? user : @user
    end
  end
  
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
    # Вернем последнее значимое
    @user= user ? user : @user
  end
  
  # Перенаправление взамен стандартному
  def redirect_back_or(path)
    redirect_to :back
    rescue ActionController::RedirectBackError
    redirect_to path
  end
end
