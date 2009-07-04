require 'digest/sha1'
class User < ActiveRecord::Base
  # Virtual attribute for the unencrypted password
  attr_accessor :password

###################################################################################################
# Валидация
###################################################################################################

  validates_uniqueness_of   :login, :case_sensitive => false, :message=>"Данный Логин уже используется"
  validates_uniqueness_of   :email, :case_sensitive => false, :message=>"Данный Email уже используется."
  validates_presence_of     :login, :email, :message=>"Поля Логин и Email не могут быть пустыми"
  
  validates_presence_of     :password,              :if => :password_required?, :message=>"Поле Пароль не может быть пустым"
  validates_presence_of     :password_confirmation, :if => :password_required?, :message=>"Необходимо подтвердить пароль"
  validates_confirmation_of :password,              :if => :password_required?, :message=>"Пароль не подтвердился"

  validates_length_of :password,
    :within => 4..40,
    :if => :password_required?,
    :message=>"Длина Пароля должна быть иной",
    :too_short=>"Пароль слишком короткий",
    :too_long=>"Пароль слишком длинный"

  validates_length_of :login,
    :within => 4..20,
    :message=>"Логин должен содержать от 4 до 20 символов",
    :too_short=>"Логин должен содержать не менее 4 символов",
    :too_long=>"Логин должен содержать не более 20 символов"
  
  validates_length_of :email,
    :within => 6..50,
    :message=>"Email должен содержать от 6 до 50 символов",
    :too_short=>"Email должен содержать не менее 5 символов",
    :too_long=>"Email должен содержать не более 50 символов"

###################################################################################################
# Пользовательские фильтры
###################################################################################################
    
  before_save :encrypt_password
  before_save :fields_downcase
  
###################################################################################################
# Пользовательский раздел
###################################################################################################

  belongs_to  :role       # У пользователя в системе одна роль
  belongs_to  :profile    # У пользователя есть профайл
  has_many    :pages      # У пользователя много страниц
  
  has_many    :personal_policies            # Пользователь имеет много персональных политик
  has_many    :personal_resource_policies   # Пользователь имеет много персональных политик по отношению к объектам
  
  # Полиморфизм работает!
  # u= User.find:first
  # prp= u.personal_resource_policies.new
  # prp.resource= u
  # prp.save => ок
  # prp.user

###################################################################################################
# Политики доступа
###################################################################################################
  
# Все базируется на Модели Role
# из нее извлекается хеш массив с полями вида
# section::action = true|false
# id | name | title | description | settings
#
#
# Модель Role обеспечивает расределение ролей по группам пользователей
# без учета временных и колличественных ограничений
# -Обеспечивает доступ группы к классу объектов
# (Группа пользователей может редактировать все деревья страниц проекта без ограничения по времени и кол-ву фактов доступа к функции)
# кроме того, организация структуры политик в виде хеш массива позволяет легко
# создавать разделы прав, действия и устанавливать значения true|false
#
# 
# GroupPolicy - надстройка над Моделью Role, обеспечивающая граничение по времени и количеству фактов доступа к функции
# Привязано к конкретной роли.
# -Обеспечивает доступ группы к классу объектов
# (Группа пользователей может редактировать все деревья страниц проекта с ограничением по времени и колву фактов доступа)
# id | role_id | section | action | value | start_at | finish_at | counter | max_count
# Для конкретного пользователя sql запросом для данной роли выбирается весь массив настроек
# формируется хеш массив, при необходимости проверки - сопостовляется и проверяется по времени, количеству фактов доступа
# при необходимости, выполняется инкрементация счетчика в БД на заданное кол-во единиц
# Интегрировано в интерфейс редактирования модели Role
#
# 
# PersonalPolicy - обеспечивает назначение права доступа некоторого пользователя на исполнение некоторой функции
# Привязанно к конкретному пользователю
# Обеспечивает временнОе и количественное ограничение использования заданной функции
# -Обеспечивает доступ персоны к группе (целому классу) объектов
# (Пользователь может редактировать все деревья страниц проекта с ограничением по времени и кол-ву фактов доступа к функции)
# id | user_id | section | action | value | start_at | finish_at | counter | max_count
#
#
# GroupResourcePolicy - обеспечивает доступ группы пользователей к выполнению функции по отношению к некоторому объекту
# Полиморфная модель
# (Группа пользователей может редактировать центральное дерево страниц и никакое иное с ограничением по времени и кол-ву фактов доступа к функции)
# Привязано к конкретной роли (группе)
# -Обеспечивает доступ группы к конкретному объекту
# id | role_id | recource_id | recource_type | section | action | value | start_at | finish_at | counter | max_count
#
#
# PersonalResourcePolicy - обеспечивает доступ пользователя к выполнению функции по отношению к некоторому объекту
# Полиморфная модель
# (Пользователь может редактировать центральное дерево страниц и никакое иное с ограничением по времени и кол-ву фактов доступа к функции)
# Привязано к конкретному пользователю
# -Обеспечивает доступ пользователя к конкретному объекту
# id | user_id | recource_id | recource_type | section | action | value | start_at | finish_at | counter | max_count
# 
# При выборке политик - выбераются сразу все. На это требуется 5 запросов.
# Сразу же формируется хеш массив со значениями
# После этого опреции производим только над хешами
# При необходимости обновить политику - выполняется запрос
# Предполагается, что за генерацию страницы будет вызван только одно обновление политик
# (или несколько, но не критическое количество или потребуется оптимизация)
# 
# Необходима функция безопасного(простого) доступа к элементу массива, что бы не проверять переменную в хеше на сущетвования

# Для обсуждения (!) Как обеспечить доступ пользователя только к конкетному списку объектов?
# (Например, прошла оплата на скачку 10 любых документов из 100 возможных)
# Создается дерево-каталог ресурсов. В конкретный раздел назначается 100 объектов
# используется PersonalResourcePolicy, определяющего доступ к данному разделу каталога и ограничение на функцию скачки в 10 единиц
# id | user_id | obj_id | obj_type          | section   | action | value | start_at | finish_at | counter | max_count
# 12 | 11      | 17     | doc_tree_section  | documents | load   | true  | null     | null      | 5       | 10
# 
# 
# 
# 
# 
# 
# 
# 
  # Возвращает хеш данной роли пользователя
  def role_settings_hash
      # Если значение роли уже определено - то вновь делать запрос и искать его не нужно
      # Если у пользователя установлена роль - то вернем ее хеш (предварительно выполнив простейшую проверку на его работоспособность)
      # В любом случае - вернем Hash, хотя бы пустой
      @role_settings_hash ||= (self.role ? (self.role.settings.is_a?(String) ? YAML::load(self.role.settings) : Hash.new) : Hash.new )
  end
  
  # Проверка на стандартное определение доступа
  # Через хеш массив таблицы Roles
  def has_policy(controller, action)
    # Если определено в массиве такое правило, то вернуть его знаение
    if role_settings_hash[controller.to_sym] && role_settings_hash[controller.to_sym][action.to_sym]
      role_settings_hash[controller.to_sym][action.to_sym] 
    else
      false
    end
  end

###################################################################################################
# Стандартные определения
###################################################################################################

  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :password, :password_confirmation
  # :role_id

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find_by_login(login) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    # Пароль шифровать не будем
    password
    #Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end
  
  # Перевести в нижний регистр логин и email
  def fields_downcase
    login.downcase!
    email.downcase!
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    # Сколько дней хранить данные об авторизации
    remember_me_for 3.days
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  protected
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end
      
    def password_required?
      crypted_password.blank? || !password.blank?
    end
end
