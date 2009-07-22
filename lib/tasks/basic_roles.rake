# Базовые роли пользователей
namespace :db do
  namespace :roles do
  
    # rake db:roles:create
    desc 'create basic roles for project'
    task :create => :environment do
      # РОЛЬ АДМИНИСТРАТОРА ПОРТАЛА
      Factory.create(:administrator_role)
      
      # РОЛЬ ЗАРЕГИСТРИРОВАННОГО ПОЛЬЗОВАТЕЛЯ
      Factory.create(:registrated_user_role)

      # РОЛЬ ЗАВЕРЕННОГО ПОЛЬЗОВАТЕЛЯ
      Factory.create(:guaranted_user_role)
      
      # РОЛЬ АДМИНИСТРАТОРА ШКОЛЬНОГО САЙТА
      Factory.create(:site_administrator_role)
    end# rake db:roles:create
  end#:roles
end#:db