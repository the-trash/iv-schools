# Данные по умолчанию для сайта
namespace :db do
  # rake db:basic_data
  desc 'create basic data'
  task :basic_data => ["db:drop", "db:create:all", "db:migrate", "db:users:roles", "db:users:create"]
      
  # Раздел создания базовых пользователей системы
  namespace :users do
    
    # rake db:users:roles
    desc 'create basic roles'
    task :roles => :environment do
      require 'factory_girl'            # Подключаем свозможность создания фабрик # Необходим гем factory_girl
      Factory.define :role do |r| end   # Создал фабрику для Ролей доступа (Role)
      
      #-------------------------------------------------------------------------------------------------------
      # Правовые группы
      #-------------------------------------------------------------------------------------------------------
      # Правовой набор администратора портала (Групповой набор)
      policy_set={
        'pages'=>{
          'manager'=>true
        }
      }#policy_set
      
      Factory.create(:role,
        :name => 'administrator',
        :title => 'Администратор портала',
        :description=>'Правовой набор администратора портала',
        :settings=> policy_set.to_yaml
      )
      
      Factory.create(:role,
        :name => 'site_administrator',
        :title => 'Администратор сайта',
        :description=>'Правовой набор администратора сайта',
        :settings=> policy_set.to_yaml
      )
      #-------------------------------------------------------------------------------------------------------
      # ~Правовые группы
      #-------------------------------------------------------------------------------------------------------
            
    end
    
    # rake db:users:create
    desc 'create basic users'
    task :create => :environment do
      # factory_girl
      require 'factory_girl'            # Подключаем свозможность создания фабрик # Необходим гем factory_girl
      Factory.define :user do |u| end   # Создал фабрику для Пользователя (User)
      Factory.define :profile do |pf| end   # Создал фабрику для Профиля пользователя (Profile)

      #-------------------------------------------------------------------------------------------------------
      # Настройки для профайла пользователя
      #-------------------------------------------------------------------------------------------------------
      profile_set={
        'access'=>{
          'info'=>true,
          'contacts'=>true,
          'birthday'=>true
        }
      }#profile_set
      #-------------------------------------------------------------------------------------------------------
      # ~Настройки для профайла пользователя
      #-------------------------------------------------------------------------------------------------------
      
      #-------------------------------------------------------------------------------------------------------
      # Администратор портала
      #-------------------------------------------------------------------------------------------------------
      # Учетная запись администратора
      admin_user= Factory.create(:user,
        :login => 'admin',
        :email => 'admin@iv-schools.ru',
        :crypted_password=>'admin',
        :salt=>'salt',
        :name=>'Зыкин Илья Николаевич',
        :role_id=>Role.find_by_name('administrator').id
      )

      # Профайл пользователя
      admins_profile= Factory.create(:profile,
        :user_id => admin_user.id,
        :birthday => (DateTime.now-24.years),
        :native_town=>'пос. Кадыкчан, Магаданская область',
        
        :home_phone => '',
        :cell_phone =>'+7 915 825 89 99',
        :icq => 'не помню',
        :jabber => 'нет',
        :public_email => 'killich@mail.ru',
        :web_site => 'iv-schools.ru',

        :activity => 'Интернет разработка, Преподавание информатики',
        :interests => 'Информационные технологии и безопасность, танцы, музыка, стихи',
        :music => 'Хорошая и разная. От классики до качественной электронной музыки',
        :movies => 'Достучаться до небес',
        :tv => 'Прожектор пересхилтон',
        :books =>'Мастер и Маргарита',
        :citation => 'Я часть той силы, что вечно хочет зла, но сотворяет благо...',
        :about_myself => 'надеюсь, что для большинства я просто хороший человек',

        :study_town  => 'Шуя',
        :study_place => 'ШГПУ',
        :study_status => 'Аспирант',

        :work_town  => 'Иваново',
        :work_place => 'Школа №36',
        :work_status => 'Преподаватель информатики',

        :setting => profile_set.to_yaml 
      )
      
      # Связать пользователя и его профайл
      admin_user.update_attribute(:profile_id, admins_profile.id)
      #-------------------------------------------------------------------------------------------------------
      # ~Администратор портала
      #-------------------------------------------------------------------------------------------------------
      
      logins= %w{ iv36 iv43 kohma5 kohma6 kohma7 kohma5vecher }
      logins.each do |login|
        #-------------------------------------------------------------------------------------------------------
        # Администратор сайта X
        #-------------------------------------------------------------------------------------------------------
        # Учетная запись администратора сайта
        user= Factory.create(:user,
          :login => "#{login}",
          :email => "#{login}@iv-schools.ru",
          :crypted_password=>"#{login}",
          :salt=>'salt',
          :name=>"Администратор сайта #{login}.iv-schools.ru",
          :role_id=>Role.find_by_name('site_administrator').id
        )
             
        # Профайл пользователя
        profile= Factory.create(:profile,
          :user_id => user.id,
          :birthday => (DateTime.now-30.years),
          :work_town  => 'Иваново',
          :work_place => "Школа #{login}",
          :work_status => 'Преподаватель информатики',

          :setting => profile_set.to_yaml 
        )
        
        # Связать пользователя и его профайл
        user.update_attribute(:profile_id, profile.id)
        #-------------------------------------------------------------------------------------------------------
        # ~Администратор сайта X
        #-------------------------------------------------------------------------------------------------------
      end#logins.each
    end# db:users:create    
  end#:users
end#:db