require 'digest/sha1'
class User < ActiveRecord::Base
  # Virtual attribute for the unencrypted password
  attr_accessor :password

###################################################################################################
# Валидация
###################################################################################################

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
# NAMED SCOPES
###################################################################################################

  # named_scope только лишь прибавляет параметры к выборке, но не более
  # Через него не выполняется поиск объектов другой модели
  # named_scope :recent, lambda { |*args| {:conditions => ["released_at > ?", (args.first || 2.weeks.ago)]} }
  # User.recent(1.day.ago)
  
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

###################################################################################################
# Интерфейсы к системе правового разграничения
###################################################################################################
# has_role_policy?(:pages, :show)
# 
# has_group_access?(:pages, :show)
# has_group_block?(:pages, :show)
# 
# has_personal_access?(:pages, :show)
# has_personal_block?(:pages, :show)
# 
# has_group_access_to_resource?(@comment, :comment, :edit)
# has_group_block_to_resource?(@comment, :comment, :edit)
# 
# has_personal_access_to_resource?(@comment, :comment, :edit)
# has_personal_block_to_resource?(@comment, :comment, :edit)

# Хеши
# 
# role_policies_hash
# group_policies_hash
# personal_policies_hash
# group_resources_policies_hash
# personal_resources_policies_hash

###################################################################################################
# Базовые функции проверки доступа/блокировки
###################################################################################################

  def get_policy_hash(options = {})
    options = {
      :finder =>      false,
      :hash_name =>   false,
      :before_find => false, 
      :recalculate => false
    }.merge(options)
    # options[:before_find] - Эта опция создана специально для group_policies_hash
    # Там необходима проверка перед выполнением поиска записей. Проверка необходима во многом для подстраховки
    # Но все же пренебрегать ей я не хочу
    return Hash.new unless (options[:finder] || options[:hash_name])
    # Выбрать все персональные политики данного пользователя
    # Сформировать хеш персональных политик
    # Иногда требуется принудительный пересчет options[:recalculate]
    eval("@#{options[:hash_name]} = nil if options[:recalculate]")
    # original: @personal_policies_hash= nil if options[:recalculate]
    # Если хеш персональных политик уже сформирован - вернем его, иначе начнем его формирование
    eval("return @#{options[:hash_name]} if @#{options[:hash_name]}")
    # original: return @personal_policies_hash if @personal_policies_hash
    result_hash= Hash.new
    eval("@#{options[:hash_name]} = result_hash")
    # original: @personal_resources_policies_hash = result_hash
    eval(options[:before_find]) if options[:before_find]
    # original: return @group_policies_hash unless self.role
    eval(options[:finder]).each do |policy|
    #original: PersonalPolicy.find_all_by_user_id(self.id).each do |policy|
      # В любом случае создаем хеш политики
      # здесь все значения о данной политике под ее именем
      _action_hash={
        policy.action.to_sym=>{
          :value=>policy.value,
          :start_at=>policy.start_at,
          :finish_at=>policy.finish_at,
          :counter=>policy.counter,
          :max_count=>policy.max_count
        }
      }
      # Если ключ(раздел политик) уже имеется, то к ключу(разделу) нужно присоединить только доп. действие(политику)
      if result_hash.has_key?(policy.section.to_sym)
        result_hash[policy.section.to_sym].merge!(_action_hash) # добавляем в раздел новую политику
      else
        _hash={ policy.section.to_sym => _action_hash }         # Если раздела нет - то создадим хеш: имя_раздела=>политика
        result_hash.merge!(_hash)                               # Соединим с исходным хешем
      end#if result_hash.has_key?(policy.section.to_sym)
    end#eval(options[:finder]).each do |policy|
    eval("@#{options[:hash_name]}= result_hash")                # Вернуть результат
    #original: @personal_policies_hash= result_hash             # Вернуть результат
  end
  
  # Актуальна ли политика пользователя по кол-ву обращений
  def policy_actual_by_counter?(counter, max_count)
    # Приходят: счетчик и его макс значение
    # Если макс.значение не существует (т.е. по обращениям не ограничено) - возвращаем true
    # Если макс.значение существует, но не существует счетчик - вернуть true
    # Если счетчик и макс.значение существуют - то сравнить их
    return true unless (max_count || counter)
    counter <= max_count
  end
  
  # Актуальна ли политика пользователя по времени действия
  def policy_actual_by_time?(start_at, finish_at)
    # Если не установлена нижняя и верхняя границы - вернуть true
    # Судя по wikipedia логическое выражение ((~x)&(~y)) - стрелка Пирса (NOR) <<<<<<<<<<<<<<
    # Если нижняя граница не существует - вернуть проверку на актуальность по верхней границе
    # Если верхняя граница не существует - вернуть проверку на актуальность по нижней границе
    # Если существуют обе границы - комплексная проверка и по нижней и по верхней границе
    return true if (!start_at && !finish_at)
    now= DateTime.now
    return (finish_at.to_datetime >= now) unless start_at
    return (start_at.to_datetime  <= now) unless finish_at
    start_at.to_datetime <= now && now <= finish_at.to_datetime
  end

  def check_access(section, action, hash_fn, options = {})
    options = {
      :recalculate => false
    }.merge(options)
    # true если
    # политика существует &&
    # Политика актуальна по времени и кол-ву доступа &&
    # Политика является неким значением и не является false значением
    # false если
    # Политики не существует  ||
    # Политики не актуальна   ||
    # Политика сущестует и актуальна, но имеет false значение
    # Выбрать весь набор политик данного раздела
    # Первый элемент - это и есть искомый хеш группы
    section_of_policies_hash=  send("#{hash_fn}", options).values_at(section.to_sym) ? send("#{hash_fn}", options).values_at(section.to_sym).first : nil
    # original: section_of_policies_hash=  personal_policies_hash(:recalculate=>options[:recalculate]).values_at(section.to_sym) ? personal_policies_hash(:recalculate=>options[:recalculate]).values_at(section.to_sym).first : nil
    # Если группа политик не существует - вернуть false
    return false unless section_of_policies_hash
    # Выбрать хеш данных для необходимой политики. Первый элемент массива и есть необходимый хеш
    policy_hash= section_of_policies_hash.values_at(action.to_sym) ? section_of_policies_hash.values_at(action.to_sym).first : nil
    # Если политика в группе политик не существует - вернуть false
    return false unless policy_hash
    # Группа политик существует и необходимая политика существует!
    # Необходимо проверить политику на колличество доступа и на время и вернуть значение установленное политикой
    # Значение политики
    # Актуальность по счетчику доступа
    # Актуальность по времени    
    value=  policy_hash[:value]
    # Проверка политики на актуальность по времени действия
    # Проверка политики на актуальность по количеству обращений
    time_check=     policy_actual_by_time?(policy_hash[:start_at], policy_hash[:finish_at])
    counter_check=  policy_actual_by_counter?(policy_hash[:counter], policy_hash[:max_count])
    # original: counter_check= policy_hash[:counter] <= policy_hash[:max_count]
    # original: time_check= policy_hash[:start_at].to_datetime <= DateTime.now && DateTime.now <= policy_hash[:finish_at].to_datetime
    #вернуть значение политики доступа
    return value if counter_check && time_check
    false
  end# check_access(section, action, hash_fn, options = {})
  
  def check_block(section, action, hash_fn, options = {})
    options = {
      :recalculate => false
    }.merge(options)
    # true если
    # политика существует &&
    # Политика актуальна по времени и кол-ву доступа &&
    # Политика является false значением    
    # false если
    # Политики не существует  ||
    # Политики не актуальна   ||
    # Политика сущестует и актуальна, но имеет НЕ false значение
    section_of_policies_hash=  send("#{hash_fn}", options).values_at(section.to_sym) ? send("#{hash_fn}", options).values_at(section.to_sym).first : nil
    return false unless section_of_policies_hash
    policy_hash= section_of_policies_hash.values_at(action.to_sym) ? section_of_policies_hash.values_at(action.to_sym).first : nil
    return false unless policy_hash
    value=  policy_hash[:value]
    time_check=     policy_actual_by_time?(policy_hash[:start_at], policy_hash[:finish_at])
    counter_check=  policy_actual_by_counter?(policy_hash[:counter], policy_hash[:max_count])
    return !value if counter_check && time_check
    false
  end# check_block(section, action, hash_fn, options = {})
    
###################################################################################################
# Ролевая политика (Наиболее общая)
###################################################################################################

  # Возвращает хеш данной роли пользователя
  def role_policies_hash
      # Если значение роли уже определено - то вновь делать запрос и искать его не нужно
      # Если у пользователя установлена роль - то вернем ее хеш (предварительно выполнив простейшую проверку на его работоспособность)
      # В любом случае - вернем Hash, хотя бы пустой
      @role_policies_hash ||= (self.role ? (self.role.settings.is_a?(String) ? YAML::load(self.role.settings) : Hash.new) : Hash.new )
  end
  
  # Проверка политики доступа через хеш массив таблицы Roles
  def has_role_policy?(section, action)
    # Ключи хешей всегда сохранять как символы!
    # Если не определено в массиве такое правило, то вернуть false
    # иначе вернем значение правила
    return false unless role_policies_hash[section.to_sym] && role_policies_hash[section.to_sym][action.to_sym]
    role_policies_hash[section.to_sym][action.to_sym]
  end

###################################################################################################
# Персональная политика
###################################################################################################

  # Возвращает хеш персональных политик данного пользователя
  def personal_policies_hash(options = {})
    opt= {
      :finder=>'PersonalPolicy.find_all_by_user_id(self.id)',
      :hash_name=>'personal_policies_hash',
    }
    get_policy_hash options.merge!(opt)
  end
    
  # Проверка политики доступа через таблицу определений дополнительных персональных политик (с временным и колличественным ограничением)
  def has_personal_access?(section, action, options = {})
    check_access(section, action, 'personal_policies_hash', options)
  end

  # Проверка существования блокировки доступа к политике через таблицу определений дополнительных персональных политик (с временным и колличественным ограничением)
  def has_personal_block?(section, action, options = {})
    check_block(section, action, 'personal_policies_hash', options)
  end

###################################################################################################
# Групповая политика
###################################################################################################
  
  # Возвращает хеш персональных политик данного пользователя
  def group_policies_hash(options = {})
    opt= {
      :finder=>'GroupPolicy.find_all_by_role_id(self.role.id)',
      :hash_name=>'group_policies_hash',
      :before_find=>'return @group_policies_hash unless self.role'
    }
    get_policy_hash options.merge!(opt)
  end
  
  # Проверка политики доступа через таблицу определений дополнительных групповых политик (с временным и колличественным ограничением)
  def has_group_access?(section, action, options = {})
    check_access(section, action, 'group_policies_hash', options)
  end

  # Проверка существования блокировки доступа к политике через таблицу определений дополнительных групповых политик (с временным и колличественным ограничением)
  def has_group_block?(section, action, options = {})
    check_block(section, action, 'group_policies_hash', options)
  end
  
###################################################################################################
# Персональная политика к ресурсу
###################################################################################################
  # personal_resources_policies_hash

  #user.personal_resources_policies_hash[:comments][:id][:section][:action]=>{
  #                                                                         :value=>policy.value,
  #                                                                         :start_at=>policy.start_at,
  #                                                                         :finish_at=>policy.finish_at,
  #                                                                         :counter=>policy.counter,
  #                                                                         :max_count=>policy.max_count
  #                                                                        }

  #user.personal_resources_policies_hash[:resource_type]= PersonalResourcePolicy.find_all_user_id_and_resource_type(user.id, :Comments)

  def personal_resources_policies_hash_for_class_of(resource)
    # current_user.id
    # User
    # Поиск всех ресурсов данного типа
    self_id=        self.id
    resource_class=  resource.class.to_s
    # Если не существует хеша - создадим его
    @personal_resources_policies_hash= Hash.new unless @personal_resources_policies_hash
    result_hash= Hash.new
    # Если в нем нет записей об объектах данного класса
    unless @personal_resources_policies_hash[resource_class.to_sym]
      # Выбрать все записи - сформировать Hesh      
      PersonalResourcePolicy.find_all_by_user_id_and_resource_type(self_id, resource_class).each do |policy|
        result_hash[policy.id]= {
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
        #[:User][5][:profile][:edit]= {:value, :start_at, :finish_at, :max_count}
      end
      # В любом случае нужно сформировать пустую запись о правах для данного класса
      # Поскольку мы определяем по ней, была ли вызвана ранее функция нахождения персональных политик
      @personal_resources_policies_hash[resource_class.to_sym]= result_hash
    end# unless @personal_resources_policies_hash[resource_type]
    @personal_resources_policies_hash
  end
  
  # Возвращает хеш персональных политик данного пользователя к ресурсам
  def personal_resources_policies_hash(options = {})
    options = {
      :recalculate => false    # Пересчитать политики для данного класса объектов
    }.merge(options)
    # Если хеша не сущствует - создадим его
    #(@personal_resources_policies_hash= Hash.new) unless @personal_resources_policies_hash
    #@personal_resources_policies_hash
    Hash.new
  end
  
  # Проверка политики доступа через таблицу определений дополнительных персональных политик (с временным и колличественным ограничением)
  # Привязка к ресурсу
  def has_personal_resource_access_for?(object, section, action, options = {})
    options = {
      :recalculate => false,    # Пересчитать политики для данного класса объектов
      :reset => false           # Сбросить весь хеш
    }.merge(options)
    # Если опция полного сброса хеша и хеш существует - то обнулить его
    @personal_resources_policies_hash= nil if (@personal_resources_policies_hash && options[:reset])
    # Если опция полного сброса данных о политиках данного класса, хеш политик и хеш для класса объектов существует - то хеш данного класса обнулим
    @personal_resources_policies_hash[object.class.to_s.to_sym]= nil if (@personal_resources_policies_hash && @personal_resources_policies_hash[object.class.to_s.to_sym] && options[:recalculate])
    # Выборка проводится для объектов каждого класса - что бы и все не выбирать
    # И не делать запрос для каждого объекта - для объектов класса один запрос - потом они хранятся в памяти
    # Если это первый вызов функции - то необходимо инициализировать хеш
    # Возможно хеш создан, но выборки для данного класса объектов еще не было - тогда сделаем еще выборку
    personal_resources_policies_hash_for_class_of(object) if !@personal_resources_policies_hash || !@personal_resources_policies_hash[object.class.to_s.to_sym]
    # >>>>> К этому моменту должен существовать хеш с записями о политиках доступа к ресурсу для данного класса объектов <<<<<
    # Если нет ни одного ресурса данной группы - вернем false (нет группы)
    # Вернуть false если раздел для данного класса существует, но пустой
    # т.е. выборка была - но оказалась пустой - (так мы ориентируемся - была ли сделана выборка)
    return false if @personal_resources_policies_hash[object.class.to_s.to_sym].empty?
    # Если нет ресурса с данным id в данной группе - вернем false
    return false unless @personal_resources_policies_hash[object.class.to_s.to_sym][object.id]
    # Если нет группы политик для данного объекта
    return false unless @personal_resources_policies_hash[object.class.to_s.to_sym][object.id][section.to_sym]
    # Если нет требуемой политики в группе политик для данного объекта
    return false unless @personal_resources_policies_hash[object.class.to_s.to_sym][object.id][section.to_sym][action.to_sym]
    # >>>>> Если мы здесь - значит у нас есть информации о конкретной политике к конкретному объекту <<<<<
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
    @personal_resources_policies_hash[object.class.to_s.to_sym]= nil  if (@personal_resources_policies_hash && @personal_resources_policies_hash[object.class.to_s.to_sym] && options[:recalculate])
    personal_resources_policies_hash_for_class_of(object)             if !@personal_resources_policies_hash || !@personal_resources_policies_hash[object.class.to_s.to_sym]
    return false if     @personal_resources_policies_hash[object.class.to_s.to_sym].empty?
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
  
###################################################################################################
# Групповая политика к ресурсу
###################################################################################################
  # group_resources_policies_hash
  
  # Проверка политики доступа через таблицу определений дополнительных групповых политик (с временным и колличественным ограничением)
  # Привязка к ресурсу
  def has_group_resource_access_for?(object, section, action, options = {})
    options = {
      :recalculate => false
    }.merge(options)
    nil
  end
  def has_group_resource_block_for?(object, section, action, options = {})
    options = {
      :recalculate => false
    }.merge(options)
    nil
  end

###################################################################################################
# Стандартные определения
###################################################################################################

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
