# Данные по умолчанию для сайта
namespace :db do
  # rake db:basic_data
  desc 'create basic data'
  
  task :basic_data => ['db:drop', 'db:create', 'db:migrate', 'db:roles:create', 'db:users:create', 'db:import:start', 'db:import:asks']
      
  # Раздел создания базовых пользователей системы
  namespace :users do
    # rake db:users:create
    desc 'create basic users'
    task :create => :environment do
    
      require "#{RAILS_ROOT}/spec/factories/users"
      require "#{RAILS_ROOT}/spec/factories/profile"

      def zip_for_model(class_name)
        zip= "#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}"
        while class_name.to_s.camelize.constantize.find_by_zip(zip)
          zip= "#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}"
        end
        zip
      end
    
      # Создать администратора
      user= Factory.create(:user,
        :login => 'portal',
        :zip=> zip_for_model(:user),
        :email => 'admin@iv-schools.ru',
        :crypted_password=>'admin',
        :salt=>'salt',
        :name=>'Зыкин Илья Николаевич',
        :role_id=>Role.find_by_name('administrator').id
      )
      profile= Factory.create(:empty_profile, :user_id => user.id)
      
      #--------------------------------------------------------------
      s_zip= zip_for_model('StorageSection')
      ss= StorageSection.new(:user_id=>user.id, :name=>'Основное', :zip=>s_zip)
      ss.save!
      #--------------------------------------------------------------
      
      #-------------------------------------------------------------------------------------------------------
      # ~Администратор портала
      #-------------------------------------------------------------------------------------------------------
      
      logins= %w{ iv36 iv43 kohma5 kohma6 kohma7 kohma5vecher }

      logins.each do |login|
        user= Factory.create(:user,
          :login => "#{login}",
          :zip=> zip_for_model(:user),
          :email => "#{login}@iv-schools.ru",
          :crypted_password=>"#{login}",
          :salt=>'salt',
          :name=>"Администратор",
          :role_id=>Role.find_by_name('site_administrator').id
        )
        profile= Factory.create(:empty_profile, :user_id => user.id)
      end#logins.each
      
      # Администраторы страниц портала
      logins= %w{ moderator001 moderator002 moderator003 } 
      logins.each do |login|
        user= Factory.create(:user,
          :login => "#{login}",
          :zip=> zip_for_model(:user),
          :email => "#{login}@iv-schools.ru",
          :crypted_password=>"#{login}",
          :salt=>'salt',
          :name=>"Модератор",
          :role_id=>Role.find_by_name('page_administrator').id
        )
        profile= Factory.create(:empty_profile, :user_id => user.id)
      end#logins.each
      
    end# db:users:create
  end#:users
end#:db