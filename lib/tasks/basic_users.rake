# Данные по умолчанию для сайта
namespace :db do
  # rake db:basic_data
  desc 'create basic data'
  task :basic_data => ['db:drop', 'db:create:all', 'db:migrate', 'db:roles:create', 'db:users:create', 'db:pages:create']
      
  # Раздел создания базовых пользователей системы
  namespace :users do
    # rake db:users:create
    desc 'create basic users'
    task :create => :environment do

      # Создать администратора
      user= Factory.create(:user,
        :login => 'portal',
        :email => 'admin@iv-schools.ru',
        :crypted_password=>'admin',
        :salt=>'salt',
        :name=>'Зыкин Илья Николаевич',
        :role_id=>Role.find_by_name('administrator').id
      )
      profile= Factory.create(:empty_profile, :user_id => user.id)
      
      #-------------------------------------------------------------------------------------------------------
      # ~Администратор портала
      #-------------------------------------------------------------------------------------------------------
      
      logins= %w{ iv36 iv43 kohma5 kohma6 kohma7 kohma5vecher }

      logins.each do |login|
        user= Factory.create(:user,
          :login => "#{login}",
          :email => "#{login}@iv-schools.ru",
          :crypted_password=>"#{login}",
          :salt=>'salt',
          :name=>"Администратор сайта #{login}.iv-schools.ru",
          :role_id=>Role.find_by_name('site_administrator').id
        )
        profile= Factory.create(:empty_profile, :user_id => user.id)
      end#logins.each
      
      # Администраторы страниц портала
      logins= %w{ page-administrator001 page-administrator002 page-administrator003 } 
      logins.each do |login|
        user= Factory.create(:user,
          :login => "#{login}",
          :email => "#{login}@iv-schools.ru",
          :crypted_password=>"#{login}",
          :salt=>'salt',
          :name=>"Администратор страниц портала #{login}.iv-schools.ru",
          :role_id=>Role.find_by_name('page_administrator').id
        )
        profile= Factory.create(:empty_profile, :user_id => user.id)
      end#logins.each
      
    end# db:users:create
  end#:users
end#:db