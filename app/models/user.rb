require 'digest/sha1'
class User < ActiveRecord::Base
  # Действуй как абонент
  acts_as_abonent
  
  # Virtual attribute for the unencrypted password
  attr_accessor :password

  # Валидация
  validates_uniqueness_of   :login, :case_sensitive => false, :message=>Messages::UserValidation[:uniqueness_of_login]
  validates_uniqueness_of   :email, :case_sensitive => false, :message=>Messages::UserValidation[:uniqueness_of_email]
  validates_presence_of     :login, :email, :message=>Messages::UserValidation[:presence_of_login_email]
  
  validates_presence_of     :password,              :if => :password_required?, :message=>Messages::UserValidation[:presence_of_password]
  validates_presence_of     :password_confirmation, :if => :password_required?, :message=>Messages::UserValidation[:presence_of_password_confirmation]
  validates_confirmation_of :password,              :if => :password_required?, :message=>Messages::UserValidation[:confirmation_of_password]

  validates_length_of :password,
    :within => 4..40,
    :if => :password_required?,
    :message=>Messages::UserValidation[:length_of_password],
    :too_short=>Messages::UserValidation[:length_of_password_too_short],
    :too_long=>Messages::UserValidation[:length_of_password_too_long]

  validates_length_of :login,
    :within => 4..30,
    :message=>Messages::UserValidation[:length_of_login],
    :too_short=>Messages::UserValidation[:length_of_login_too_short],
    :too_long=>Messages::UserValidation[:length_of_login_too_long]
  
  validates_length_of :email,
    :within => 6..50,
    :message=>Messages::UserValidation[:length_of_email],
    :too_short=>Messages::UserValidation[:length_of_email_too_long],
    :too_long=>Messages::UserValidation[:length_of_email_too_long]

  # Пользовательские фильтры
  before_save :encrypt_password
  before_save :fields_downcase

  # Пользовательский раздел
  belongs_to  :role                         # У пользователя в системе одна роль
  has_one     :profile                      # У пользователя есть профайл
  has_many    :pages                        # У пользователя много страниц
  
  has_many    :personal_policies            # Пользователь имеет много персональных политик
  has_many    :personal_resource_policies   # Пользователь имеет много персональных политик по отношению к объектам

#----------------------------------------------------------------------------
# Стандартные определения
#----------------------------------------------------------------------------
  
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :password, :password_confirmation
  
  # Перевести в нижний регистр логин и email
  def fields_downcase
    login.downcase!
    email.downcase!
  end
    
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

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    # Сколько дней хранить данные об авторизации
    remember_me_for 3.days
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

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  # Данную функцию я добавил, для генерации token'а
  # поскольку отключено шифрование пароля пользователя
  def encryptSHA(word)
    Digest::SHA1.hexdigest(word)
  end
  
  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encryptSHA("#{email}--#{remember_token_expires_at}")
    #self.remember_token           = encrypt("#{email}--#{remember_token_expires_at}")
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