# Политики по умолчанию для пользователей
namespace :db do
  namespace :roles do
    desc 'create test policies for users'
    # rake db:roles:policies
    task :policies => :environment do
      require 'factory_girl'
      
      Factory.define :group_policy do |gp| end              # Создал фабрику для Надстройки для групповой политики (GroupPolicy)
      Factory.define :group_resource_policy do |grp| end    # Создал фабрику для групповой политики для объекта (GroupResourcePolicy)
      
      Factory.define :personal_policy do |pp| end              # Создал фабрику для персональной политики (PersonalPolicy)
      Factory.define :personal_resource_policy do |prp| end    # Создал фабрику для персональной политики для объекта (PersonalResourcePolicy)
      
      # Найти первого пользователя
      user= User.find:first
      
      ['edit', 'update', 'create', 'destroy', 'rename'].each do |act|
        # Персональная политика для данного пользователя
        Factory.create(:personal_policy,
          :user_id => user.id, 
          :section => 'pages',
          :action => act,
          :value => 'true',
          :start_at=>DateTime.now,
          :finish_at=>DateTime.now + 3.days,
          :counter=>5,
          :max_count=>15
        )
      end
      
      
    end# db:roles:policies
  end#:roles
end#:db