# Базовые роли пользователей
namespace :db do
  namespace :roles do
  
    # rake db:roles:create
    desc 'create basic roles for project'
    task :create => :environment do
      
      # РОЛЬ АДМИНИСТРАТОРА ПОРТАЛА
      policy= {
        :administrator=>{
          :pages=>true,
          :documents=>true,
          :blogs=>true,
          :albums=>true,
          :forums=>true
        }
      }
      Factory.define :administrator_role, :class => Role do |r|
        r.name   'administrator'
        r.title 'Администратор портала'
        r.description 'Правовой набор Администратора портала'
        r.settings(policy.to_yaml)
      end
      Factory.create(:administrator_role)
      # РОЛЬ АДМИНИСТРАТОРА ПОРТАЛА

      # РОЛЬ ЗАРЕГИСТРИРОВАННОГО ПОЛЬЗОВАТЕЛЯ
      policy= {
        :pages=>{
          :index=>true,
          :show=>true
        },
        :documents=>{
          :index=>true,
          :show=>true
        },
        :blogs=>{
          :index=>true,
          :show=>true
        },
        :albums=>{
          :index=>true,
          :show=>true
        },
        :forums=>{
          :index=>true,
          :show=>true
        }
      }
      Factory.define :registrated_user_role, :class => Role do |r|
        r.name   'registrated_user'
        r.title 'Зарегистрированный пользователь'
        r.description 'Правовой набор зарегистрированного пользователя'
        r.settings(policy.to_yaml)
      end
      Factory.create(:registrated_user_role)
      # РОЛЬ ЗАРЕГИСТРИРОВАННОГО ПОЛЬЗОВАТЕЛЯ
      
      # РОЛЬ ЗАВЕРЕННОГО ПОЛЬЗОВАТЕЛЯ
      policy= {
        :pages=>{
          :index=>true,
          :show=>true
        },
        :documents=>{
          :index=>true,
          :show=>true
        },
        :blogs=>{
          :index=>true,
          :show=>true,
          :new=>true,
          :create=>true,
          :edit=>true,
          :update=>true,
          :destroy=>true
        },
        :albums=>{
          :index=>true,
          :show=>true,
          :new=>true,
          :create=>true,
          :edit=>true,
          :update=>true,
          :destroy=>true
        },
        :forums=>{
          :index=>true,
          :show=>true
        }
      }
      Factory.define :guaranted_user_role, :class => Role do |r|
        r.name   'guaranted_user_role'
        r.title 'Заверенный пользователь'
        r.description 'Правовой набор заверенного пользователя'
        r.settings(policy.to_yaml)
      end
      Factory.create(:guaranted_user_role)
      # РОЛЬ ЗАВЕРЕННОГО ПОЛЬЗОВАТЕЛЯ
      
      # РОЛЬ АДМИНИСТРАТОРА ШКОЛЬНОГО САЙТА
      policy= {
        :pages=>{
          :index=>true,
          :show=>true,
          :manager=>true,
          :new=>true,
          :create=>true,
          :edit=>true,
          :update=>true,
          :destroy=>true,
          :up=>true,
          :down=>true,
        },
        :documents=>{
          :index=>true,
          :show=>true,
          :new=>true,
          :create=>true,
          :edit=>true,
          :update=>true,
          :destroy=>true
        },
        :blogs=>{
          :index=>true,
          :show=>true,
          :new=>true,
          :create=>true,
          :edit=>true,
          :update=>true,
          :destroy=>true
        },
        :albums=>{
          :index=>true,
          :show=>true,
          :new=>true,
          :create=>true,
          :edit=>true,
          :update=>true,
          :destroy=>true
        },
        :forums=>{
          :index=>true,
          :show=>true,
          :new=>true,
          :create=>true,
          :edit=>true,
          :update=>true,
          :destroy=>true
        }
      }
      Factory.define :site_administrator_role, :class => Role do |r|
        r.name   'site_administrator_role'
        r.title 'Администратор школьного сайта'
        r.description 'Правовой набор администратора школьного сайта'
        r.settings(policy.to_yaml)
      end
      Factory.create(:site_administrator_role)
      # РОЛЬ АДМИНИСТРАТОРА ШКОЛЬНОГО САЙТА
    end# rake db:roles:create
  end#:roles
end#:db