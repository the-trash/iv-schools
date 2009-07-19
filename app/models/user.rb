require 'digest/sha1'
class User < ActiveRecord::Base
  # Virtual attribute for the unencrypted password
  attr_accessor :password

# Валидация

  validates_uniqueness_of   :login, :case_sensitive => false, :message=>"Данный Логин уже используется 111"
  validates_uniqueness_of   :email, :case_sensitive => false, :message=>"Данный Email уже используется. 222"
  validates_presence_of     :login, :email, :message=>"Поля Логин и Email не могут быть пустыми 333"
  
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

# Пользовательские фильтры

  before_save :encrypt_password
  before_save :fields_downcase

# Пользовательский раздел

  belongs_to  :role                         # У пользователя в системе одна роль
  belongs_to  :profile                      # У пользователя есть профайл
  has_many    :pages                        # У пользователя много страниц
  
  has_many    :personal_policies            # Пользователь имеет много персональных политик
  has_many    :personal_resource_policies   # Пользователь имеет много персональных политик по отношению к объектам

# Ролевая политика (Наиболее общая)

  def role_policies_hash
    @role_policies_hash ||= (self.role ? (self.role.settings.is_a?(String) ? YAML::load(self.role.settings) : Hash.new) : Hash.new )
  end
  
  def has_role_policy?(section, action)
    return false unless role_policies_hash[section.to_sym] && role_policies_hash[section.to_sym][action.to_sym]
    role_policies_hash[section.to_sym][action.to_sym]
  end

# Tested
# role_policies_hash
# has_role_policy?

# Базовые функции проверки доступа/блокировки

  def policy_actual_by_counter?(counter, max_count)
    return true if (!max_count || !counter)
    counter <= max_count
  end

  def policy_actual_by_time?(start_at, finish_at)
    return true if (!start_at && !finish_at)
    now= DateTime.now
    return (finish_at.to_datetime >= now) unless start_at
    return (start_at.to_datetime  <= now) unless finish_at
    start_at.to_datetime <= now && now <= finish_at.to_datetime
  end

# Tested
# policy_actual_by_counter?(counter, max_count)
# policy_actual_by_time?(start_at, finish_at)

  def get_policy_hash(options = {})
    options = {
      :finder =>      false,
      :hash_name =>   false,
      :before_find => false, 
      :recalculate => false
    }.merge(options)
    return Hash.new unless (options[:finder] || options[:hash_name])
    eval("@#{options[:hash_name]} = nil  if options[:recalculate]")
    eval("return @#{options[:hash_name]} if @#{options[:hash_name]}")
    result_hash= Hash.new
    eval("@#{options[:hash_name]} = result_hash")
    eval(options[:before_find]) if options[:before_find]
    eval(options[:finder]).each do |policy|
      _action_hash={
        policy.action.to_sym=>{
          :value=>policy.value,
          :start_at=>policy.start_at,
          :finish_at=>policy.finish_at,
          :counter=>policy.counter,
          :max_count=>policy.max_count
        }
      }
      if result_hash.has_key?(policy.section.to_sym)
        result_hash[policy.section.to_sym].merge!(_action_hash)
      else
        _hash={ policy.section.to_sym => _action_hash }        
        result_hash.merge!(_hash)                              
      end
    end
    eval("@#{options[:hash_name]}= result_hash")
  end
  
  def check_policy(section, action, hash_fn, options = {})
    options = {
      :recalculate => false,
      :return_invert=>false
    }.merge(options)
    section_of_policies_hash=  send("#{hash_fn}", options).values_at(section.to_sym) ? send("#{hash_fn}", options).values_at(section.to_sym).first : nil
    return false unless section_of_policies_hash
    policy_hash= section_of_policies_hash.values_at(action.to_sym) ? section_of_policies_hash.values_at(action.to_sym).first : nil
    return false unless policy_hash
    # Если установлена инвертация значения политики - значит проверка на блокировку
    value= options[:return_invert] ? !policy_hash[:value] : policy_hash[:value]
    time_check=     policy_actual_by_time?(policy_hash[:start_at], policy_hash[:finish_at])
    counter_check=  policy_actual_by_counter?(policy_hash[:counter], policy_hash[:max_count])
    return value if counter_check && time_check
    false
  end

# Персональная политика

  def personal_policies_hash(options = {})
    opt= {
      :finder=>'PersonalPolicy.find_all_by_user_id(self.id)',
      :hash_name=>'personal_policies_hash',
    }
    get_policy_hash options.merge!(opt)
  end

  def has_personal_access?(section, action, options = {})
    check_policy(section, action, 'personal_policies_hash', options)
  end

  def has_personal_block?(section, action, options = {})
    opt={
      :return_invert=>true
    }
    check_policy(section, action, 'personal_policies_hash', options.merge!(opt))
  end
  
# Tested
# has_personal_access?(section, action, options = {})
# has_personal_block?(section, action, options = {})

# Групповая политика

  def group_policies_hash(options = {})
    opt= {
      :finder=>'GroupPolicy.find_all_by_role_id(self.role.id)',
      :hash_name=>'group_policies_hash',
      :before_find=>'return @group_policies_hash unless self.role'
    }
    get_policy_hash options.merge!(opt)
  end

  def has_group_access?(section, action, options = {})
    check_policy(section, action, 'group_policies_hash', options)
  end

  def has_group_block?(section, action, options = {})
    opt={
      :return_invert=>true
    }
    check_policy(section, action, 'group_policies_hash', options.merge!(opt))
  end
  
# Tested
# has_group_access?(section, action, options = {})
# has_group_block?(section, action, options = {})
  
# Персональная политика к ресурсу

  def personal_resources_policies_hash_for_class_of(resource)
    self_id=        self.id
    resource_class=  resource.class.to_s
    @personal_resources_policies_hash= Hash.new unless @personal_resources_policies_hash
    result_hash= Hash.new
    unless @personal_resources_policies_hash[resource_class.to_sym]
      PersonalResourcePolicy.find_all_by_user_id_and_resource_type(self_id, resource_class).each do |policy|
        result_hash[policy.resource_id]= {
          policy.section.to_sym=>{
            policy.action.to_sym=>{
              :value=>policy.value,
              :start_at=>policy.start_at,
              :finish_at=>policy.finish_at,
              :counter=>policy.counter,
              :max_count=>policy.max_count
            }
          } 
        }
      end
      @personal_resources_policies_hash[resource_class.to_sym]= result_hash
    end
    @personal_resources_policies_hash
  end

  def has_personal_resource_access_for?(object, section, action, options = {})
    options = {
      :recalculate => false,
      :reset => false
    }.merge(options)
    @personal_resources_policies_hash= nil if (@personal_resources_policies_hash && options[:reset])
    @personal_resources_policies_hash[object.class.to_s.to_sym]= nil if (@personal_resources_policies_hash && @personal_resources_policies_hash[object.class.to_s.to_sym] && options[:recalculate])
    personal_resources_policies_hash_for_class_of(object) if !@personal_resources_policies_hash || !@personal_resources_policies_hash[object.class.to_s.to_sym]
    return false if @personal_resources_policies_hash[object.class.to_s.to_sym].empty?
    return false unless @personal_resources_policies_hash[object.class.to_s.to_sym][object.id]
    return false unless @personal_resources_policies_hash[object.class.to_s.to_sym][object.id][section.to_sym]
    return false unless @personal_resources_policies_hash[object.class.to_s.to_sym][object.id][section.to_sym][action.to_sym]
    policy_hash= @personal_resources_policies_hash[object.class.to_s.to_sym][object.id][section.to_sym][action.to_sym]
    value=  policy_hash[:value]
    time_check=     policy_actual_by_time?(policy_hash[:start_at], policy_hash[:finish_at])
    counter_check=  policy_actual_by_counter?(policy_hash[:counter], policy_hash[:max_count])
    return value if counter_check && time_check
    false
  end
  
  def has_personal_resource_block_for?(object, section, action, options = {})
    options = {
      :recalculate => false,
      :reset => false
    }.merge(options)
    @personal_resources_policies_hash= nil if (@personal_resources_policies_hash && options[:reset])
    @personal_resources_policies_hash[object.class.to_s.to_sym]= nil if (@personal_resources_policies_hash && @personal_resources_policies_hash[object.class.to_s.to_sym] && options[:recalculate])
    personal_resources_policies_hash_for_class_of(object) if !@personal_resources_policies_hash || !@personal_resources_policies_hash[object.class.to_s.to_sym]
    return false if @personal_resources_policies_hash[object.class.to_s.to_sym].empty?
    return false unless @personal_resources_policies_hash[object.class.to_s.to_sym][object.id]
    return false unless @personal_resources_policies_hash[object.class.to_s.to_sym][object.id][section.to_sym]
    return false unless @personal_resources_policies_hash[object.class.to_s.to_sym][object.id][section.to_sym][action.to_sym]
    policy_hash= @personal_resources_policies_hash[object.class.to_s.to_sym][object.id][section.to_sym][action.to_sym]
    value=  policy_hash[:value]
    time_check=     policy_actual_by_time?(policy_hash[:start_at], policy_hash[:finish_at])
    counter_check=  policy_actual_by_counter?(policy_hash[:counter], policy_hash[:max_count])
    return !value if counter_check && time_check
    false
  end

# Групповая политика к ресурсу

  def group_resources_policies_hash_for_class_of(resource)
    resource_class=  resource.class.to_s
    @group_resources_policies_hash= Hash.new unless @group_resources_policies_hash
    result_hash= Hash.new
    unless @group_resources_policies_hash[resource_class.to_sym]
      (@group_resources_policies_hash[resource_class.to_sym]= result_hash and return @group_resources_policies_hash) unless self.role
      GroupResourcePolicy.find_all_by_role_id_and_resource_type(self.role.id, resource_class).each do |policy|
        result_hash[policy.resource_id]= {
          policy.section.to_sym=>{
            policy.action.to_sym=>{
              :value=>policy.value,
              :start_at=>policy.start_at,
              :finish_at=>policy.finish_at,
              :counter=>policy.counter,
              :max_count=>policy.max_count
            }
          } 
        }
      end
      @group_resources_policies_hash[resource_class.to_sym]= result_hash
    end
    @group_resources_policies_hash
  end

  def has_group_resource_access_for?(object, section, action, options = {})
    options = {
      :recalculate => false,
      :reset => false
    }.merge(options)
    @group_resources_policies_hash= nil if (@group_resources_policies_hash && options[:reset])
    @group_resources_policies_hash[object.class.to_s.to_sym]= nil if (@group_resources_policies_hash && @group_resources_policies_hash[object.class.to_s.to_sym] && options[:recalculate])
    group_resources_policies_hash_for_class_of(object) if !@group_resources_policies_hash || !@group_resources_policies_hash[object.class.to_s.to_sym]
    return false if @group_resources_policies_hash[object.class.to_s.to_sym].empty?
    return false unless @group_resources_policies_hash[object.class.to_s.to_sym][object.id]
    return false unless @group_resources_policies_hash[object.class.to_s.to_sym][object.id][section.to_sym]
    return false unless @group_resources_policies_hash[object.class.to_s.to_sym][object.id][section.to_sym][action.to_sym]
    policy_hash= @group_resources_policies_hash[object.class.to_s.to_sym][object.id][section.to_sym][action.to_sym]
    value=  policy_hash[:value]
    time_check=     policy_actual_by_time?(policy_hash[:start_at], policy_hash[:finish_at])
    counter_check=  policy_actual_by_counter?(policy_hash[:counter], policy_hash[:max_count])
    return value if counter_check && time_check
    false
  end
  
  def has_group_resource_block_for?(object, section, action, options = {})
    options = {
      :recalculate => false,
      :reset => false
    }.merge(options)
    @group_resources_policies_hash= nil if (@group_resources_policies_hash && options[:reset])
    @group_resources_policies_hash[object.class.to_s.to_sym]= nil if (@group_resources_policies_hash && @group_resources_policies_hash[object.class.to_s.to_sym] && options[:recalculate])
    group_resources_policies_hash_for_class_of(object) if !@group_resources_policies_hash || !@group_resources_policies_hash[object.class.to_s.to_sym]
    return false if @group_resources_policies_hash[object.class.to_s.to_sym].empty?
    return false unless @group_resources_policies_hash[object.class.to_s.to_sym][object.id]
    return false unless @group_resources_policies_hash[object.class.to_s.to_sym][object.id][section.to_sym]
    return false unless @group_resources_policies_hash[object.class.to_s.to_sym][object.id][section.to_sym][action.to_sym]
    policy_hash= @group_resources_policies_hash[object.class.to_s.to_sym][object.id][section.to_sym][action.to_sym]
    value=  policy_hash[:value]
    time_check=     policy_actual_by_time?(policy_hash[:start_at], policy_hash[:finish_at])
    counter_check=  policy_actual_by_counter?(policy_hash[:counter], policy_hash[:max_count])
    return !value if counter_check && time_check
    false
  end

# Стандартные определения

  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :password, :password_confirmation

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
