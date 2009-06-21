# Данные по умолчанию для сайта
namespace :db do
  # rake db:basic_data
  desc 'create basic data'
  task :basic_data => ["db:drop", "db:create", "db:migrate", "db:users:create"]
      
  # Раздел создания базовых пользователей системы
  namespace :users do
    desc 'create basic users'
    
    
    # rake db:users:create
    task :create => :environment do
      # factory_girl
      require 'factory_girl'            # Подключаем свозможность создания фабрик # Необходим гем factory_girl
      Factory.define :user do |u| end   # Создал фабрику для Пользователя (User)
      Factory.define :role do |r| end   # Создал фабрику для Ролей доступа (Role)
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
      # Правовые группы
      #-------------------------------------------------------------------------------------------------------
      # Правовой набор администратора портала (Групповой набор)
      policy_set={
        'forum'=>{
          'index'=>true,
          'update'=>true,
          'delete'=>true
        },
        'basic'=>{
          'index'=>true,
          'update'=>true,
          'delete'=>true
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
      
      
      
      #-------------------------------------------------------------------------------------------------------
      # Администратор сайта
      #-------------------------------------------------------------------------------------------------------
      # Учетная запись администратора сайта
      user= Factory.create(:user,
        :login => 'iv36',
        :email => 'iv36@iv-schools.ru',
        :crypted_password=>'iv36',
        :salt=>'salt',
        :name=>'Скворцова Любовь Александровна',
        :role_id=>Role.find_by_name('site_administrator').id
      )
           
      # Профайл пользователя
      profile= Factory.create(:profile,
        :user_id => user.id,
        :birthday => (DateTime.now-27.years),
        :work_town  => 'Иваново',
        :work_place => 'Школа №36',
        :work_status => 'Преподаватель информатики',

        :setting => profile_set.to_yaml 
      )
      
      # Связать пользователя и его профайл
      user.update_attribute(:profile_id, profile.id)
      #-------------------------------------------------------------------------------------------------------
      # ~Администратор сайта
      #-------------------------------------------------------------------------------------------------------
      
    end# db:users:create

    desc 'create basic users pages'
    # rake db:users:pages
    task :pages => :environment do
      require 'faker'
      require 'factory_girl'
      
      # Найти всех пользователей
      users= User.find:all
      # Для каждого пользователя
      users.each do |u|
        # 10 раз сделать страницу
        10.times do
          # Создать страницу
          page= u.pages.new(
            :author=>Faker::Name.name,
            :keywords=>Faker::Lorem.sentence(2),
            :description=>Faker::Lorem.sentence(2),
            :copyright=>Faker::Name.name,
            :title=>"#{u.name} #{Faker::Lorem.sentence}",
            :annotation=>Faker::Lorem.sentence(3),
            :content=>Faker::Lorem.sentence(50)
          )
          
          page.save # Сохранить страницу
          
          # C вероятностью 50/50, что будут созданы подстраницы для данной (дерево строю)
          if [true, false].rand
            # Пять раз
            5.times do
              # Создать дочернюю страницу
              child_page= u.pages.new(
                :author=>Faker::Name.name,
                :keywords=>Faker::Lorem.sentence(2),
                :description=>Faker::Lorem.sentence(2),
                :copyright=>Faker::Name.name,
                :title=>"#{u.name} #{Faker::Lorem.sentence}",
                :annotation=>Faker::Lorem.sentence(3),
                :content=>Faker::Lorem.sentence(50)
              )
              # Сохранить дочернюю страницу
              child_page.save
              # Дочернюю страницу сделать дочкой данной страницы
              child_page.move_to_child_of page

              # ТРЕТИЙ УРОВЕНЬ
                # C вероятностью 50/50, что будут созданы подстраницы для данной (дерево строю)
                if [true, false].rand
                  # Пять раз
                  5.times do
                    # Создать дочернюю страницу
                    level_child_page= u.pages.new(
                      :author=>Faker::Name.name,
                      :keywords=>Faker::Lorem.sentence(2),
                      :description=>Faker::Lorem.sentence(2),
                      :copyright=>Faker::Name.name,
                      :title=>"#{u.name} #{Faker::Lorem.sentence}",
                      :annotation=>Faker::Lorem.sentence(3),
                      :content=>Faker::Lorem.sentence(50)
                    )
                    # Сохранить дочернюю страницу
                    level_child_page.save
                    # Дочернюю страницу сделать дочкой данной страницы
                    level_child_page.move_to_child_of child_page
                  end# n.times do
                end# [true, false].rand
              # ТРЕТИЙ УРОВЕНЬ
              
            end# n.times do
          end# [true, false].rand
          
        end# n.times do
      end# users.each do |u|
    end# db:users:pages
    
  end#:users
end#:db