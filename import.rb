Приветствую, дорогой товариСч! =)

Расскажу я тебе не о красивых обнаженных женских телах,
прекрасный вид которых давно утонул в твоем сознании под
давлением воспаленного виртуапльностью разума, и даже не о том,
как прекрасно в теплый летний вечер лежать на берегу небольшого озера и
наслаждаться теплом лучей медленно заходящего за горизонт раскаленного шара..

..зачем.. ведь этого все расно нет в твоей жизни =)

..а расскажу я тебе о том, как потратил несколько часов своей замечательной молодой жизни
на написание rake задачи, организующей перенос данных из одной БД на в другую.

И так:

Постановка задачи:

Имеем:

Локальная машина с двумя MySQL БД

БД1 => взята из 2х летнего php проекта, который переносится на рельсы
БД2 => Новая БД на рельсах с совершенно другой структурой данных

БД1 - вмещает в себе несколько десятков таблиц. БД1 использовалась несколькими экземплярами одного движка.
Таблицы каждого экземпляра имеют уникальный префикс перед именем, который можно считать Логином администратора сайта.
Основное содержимое БД1 - контентрные страницы и файлы связанные со страницами.
В БД1 организована кривая древовидная структура - Страницы хранятся в отдельной таблице - Информация о дереве в другой.

БД2 - БД под многопользовательскую Rails систему. Обладает таблицей страниц, с привязкой к конкретному пользователю и полями,
обеспечивающими функционал дерева (На основе awesome_nested_set)

Основная цель - перенести деревья страниц в новый движок и обеспечить, что информация о файлах,
прикрепленных к страницам не терялась
(ранее была программная отрисовка прикрепленных файлов - мы заменем ее на простой html поскольку
новый движок не предполагает автоматической отрисоки прикрепленных файлов)

Начинаем:

1. Создаем файл для rake и его основу:

lib\tasks\import.rake

namespace :db do
  namespace :import do
    # rake db:import:start
    desc 'import data form OldSite'
    task :start => :environment do    
      #
      #
      #
    end# db:import:start
  end# db:import
end#:db

У нас должно быть два соединения - одно с нашей текущей базой,
другое со старой базой.

Соединение с новой базой у нас будет создаваться по умолчанию - тут вопросов нет.
Соединение с другой базой мы организуем через промежуточный класс порожденный от ActiveRecord::Base

class OldSiteConnect < ActiveRecord::Base
    establish_connection(
      :adapter  => "mysql",
      :host     => "localhost",
      :username => "root",
      :password => "",
      :database => "OldSite",
      :encoding => "utf8"
    )
end

Все порожденные классы от OldSiteConnect будут с одной стороны ActiveRecord::Base
а, с другой стороны будут иметь отличное от стандартного соединение.

Обратите внимение старая база у меня в cp1251
опция :encoding => "utf8" позволила мне не думать о переконвертации текста в utf8.

У меня в старой базе три таблицы с которыми мне придетсф работать:

  class OldSiteSection < OldSiteConnect
      set_table_name "#{login}_sections"
  end    
  class OldSitePage < OldSiteConnect
      set_table_name "#{login}_pages"
  end
  class OldSiteLinkedFiles < OldSiteConnect
      set_table_name "#{login}_linked_files"
  end


set_table_name "#{login}_sections"

Функция set_table_name позволила мне изменить имя таблицы связанной с Моделью,
посколюку у меня ИМЯ МОДЕЛИ и ИМЯ ТАБЛИЦЫ БД не совпадали.
Пришлось немного обмануть ожидания ActiveRecord

Внутри класса моя внешнаяя переменная login интерпритироваться не захотела и я
не став долго думать запихнул код в eval

=) ну да да.. бросайте в меня камни =) подумаешь один eval =) а шуму то, шуму =)

Итого получаем так:

namespace :db do
  namespace :import do
    # rake db:import:start
    desc 'import data form OldSite'
    task :start => :environment do
    class OldSiteConnect < ActiveRecord::Base
        establish_connection(
          :adapter  => "mysql",
          :host     => "localhost",
          :username => "root",
          :password => "",
          :database => "OldSite",
          :encoding => "utf8"
        )
    end
    
    logins= %w{ town1 town2 town3 town4 town5 }
    
      logins.each do |login|
        user= User.find_by_login(login)
        
        eval("
          class OldSiteSection < OldSiteConnect
              set_table_name '#{login}_sections'
          end    
          class OldSitePage < OldSiteConnect
              set_table_name '#{login}_pages'
          end
          class OldSiteLinkedFiles < OldSiteConnect
              set_table_name '#{login}_linked_files'
          end
        ")
        
        sections= OldSiteSection.find(:all,  :order=>"Prev_Id ASC")
      end# logins.each do |login|
      
    end# db:import:start
  end# db:import
end#:db

И так - мы видим список логинов пользователей.
Для каждого пользователя будут переопределяться классы Модели для доступа к нужным таблицам старой БД.

Видите?! Видите?!

sections= OldSiteSection.find(:all,  :order=>"Prev_Id ASC")

Я уже обращаюсь к старой базе и получаю от туда структуру дерева страниц (там оно было названо sections)

По этой структуре sections надо выбрать страницы.
Страницы надо перенести в новую БД и построить из них дерево.
Дерево в новой БД будет строится по новым ID страниц, и не будет опираться на старые ID.
Точнее старые ID будут определять дерево, а по новым ID нужно это дерево уже строить.
 
Что бы привести все это в какое то соответствие  - я делаю ассоциативный массив.
Ключ ассоциативной пары - это старый ID страницы (в старой БД он назывался Prev_Id)
Значение ассоциативной пары - новый ID страницы в новой БД.

При создании каждой страницы я буду сохранять во внешнем хеше пары - старый ID => Новый ID
И при необходимости буду вызывать функцию перемещения страницы к предку, если в ассоциативной паре есть нужная информация.

На самом деле объяснить на словах довольно трудно - была бы у вас такая задачка - сами бы поняли что к чему.

namespace :db do
  namespace :import do
  
    # rake db:import:start
    desc 'import data form OldSite'
    task :start => :environment do
    class OldSiteConnect < ActiveRecord::Base
        establish_connection(
          :adapter  => "mysql",
          :host     => "localhost",
          :username => "root",
          :password => "",
          :database => "OldSite",
          :encoding => "utf8"
        )
    end
        
    logins= %w{ town1 town2 town3 town4 town5 }
    
      logins.each do |login|
        user= User.find_by_login(login)
        
        eval("
          class OldSiteSection < OldSiteConnect
              set_table_name '#{login}_sections'
          end    
          class OldSitePage < OldSiteConnect
              set_table_name '#{login}_pages'
          end
          class OldSiteLinkedFiles < OldSiteConnect
              set_table_name '#{login}_linked_files'
          end
        ")
        
        # перебираем все разделы (фактически это дерево)
        sections= OldSiteSection.find(:all,  :order=>"Prev_Id ASC")
        
        # Хеш для соответствия старого и нового id
        ids_set= Hash.new
        
        sections.each do |s|
          # Старый id страницы
          old_id= s.Page_Id
          # Старая страница
          basic_page= OldSitePage.find(old_id)
          
          title= basic_page.Description
          content= basic_page.Content
          
          page= Page.new( :user_id=>user.id,
                          :title=>title,
                          :content=>content
                         )
          page.save
          
          new_id= page.id
          
          # Если в спискt родителей имеется такой id, то страницу нужно переместить к родителю
          page.move_to_child_of(Page.find(ids_set[s.Prev_Id])) if ids_set[s.Prev_Id]
          
          # Добавить в список соответствий id
          ids_set[old_id] = new_id
        end# sections.each do |s|
        
      end# logins.each do |login|
    end# db:import:start
  end# db:import
end#:db

Немного пришлось прикрепить gsub поскольку в новой базе нужно было хранить разметку,
а при переносе базы скобки превратились в html эквиваленты.
Кроме того, нужно было заменить все пути у ссылок, ведущих на локальные файлы,
в новом движке все файлы хранятся централизовано =)

  title= basic_page.Description.gsub("&gt;", '>').gsub("&lt;", '<').gsub("&quot;", "'")

  content= basic_page.Content.gsub("&gt;", '>').gsub("&lt;", '<').gsub("&quot;", "'")
  
  content= content.gsub("./files/common/", "/uploads/files/#{login}/")
  content= content.gsub("./files/pages/", "/uploads/files/#{login}/")
  
  content= content.gsub("./files/#{login}/common/", "/uploads/files/#{login}/")
  content= content.gsub("./files/#{login}/pages/", "/uploads/files/#{login}/")

А еще я вспомнил, что в старом движке к странице программно прикреплялись файлы.
Я не буду заниматься написанием аналогичного программного функционала - а просто найду
все прикрепленные к странице файлы и в конце страницы сделаю список со ссылками.

Для кажой страницы я буду вызывать

  # Найти файлы если они прикреплены к странице
  files= OldSiteLinkedFiles.find(:all, :conditions => ['Page_Id = ? and Linked = ?', old_id, 1])
  
Page_Id в старом движке означал ID страницы, а Linked - это флаг того, что файл отображается,
при просмотре страницы.

  content= basic_page.Content.gsub("&gt;", '>').gsub("&lt;", '<').gsub("&quot;", "'")

  # если массив найденных файлов не пуст то к содержимому страницы присоеденяю
  # HTML список со ссылками на файлы
  (content = content + file_div(files) ) unless files.empty?

Функция file_div(files) должна генерировать HTML

Мне не хотелось использовать чистый HTML код и я хотел использовать хелпервы из ACTION VIEW

  def file_div(files)
    res= ""
    files.each do |f|
      res<< content_tag(:li, link_to(f.Description, f.Path) )
    end
    res= content_tag(:ul, res, :class=>:linked_files)
  end
  
Однако в Rake content_tag и link_to работать не захотело.

Я сделал так:

  require 'action_view/helpers/tag_helper'
  require 'action_view/helpers/url_helper'
  class Helpers
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper
  end
  
А потом в file_div(files) породил экземпляр help= Helpers.new
от которого и вызвал нужные функции.

Уж не знаю на сколько криво я это сделал - но оно работает и это главное =)

  require 'action_view/helpers/tag_helper'
  require 'action_view/helpers/url_helper'
  class Helpers
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper
  end

  def file_div(files)
    help= Helpers.new
    res= ""
    files.each do |f|
      res<< help.content_tag(:li, help.link_to(f.Description, f.Path) )
    end
    res= help.content_tag(:ul, res, :class=>:linked_files)
  end

Ну и собственно получил

namespace :db do
  namespace :import do
  
    # rake db:import:start
    desc 'import data form OldSite'
    task :start => :environment do
    class OldSiteConnect < ActiveRecord::Base
        establish_connection(
          :adapter  => "mysql",
          :host     => "localhost",
          :username => "root",
          :password => "",
          :database => "OldSite",
          :encoding => "utf8"
        )
    end
    
    require 'action_view/helpers/tag_helper'
    require 'action_view/helpers/url_helper'
    class Helpers
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::UrlHelper
    end

    def file_div(files)
      help= Helpers.new
      res= ""
      files.each do |f|
        res<< help.content_tag(:li, help.link_to(f.Description, f.Path) )
      end
      res= help.content_tag(:ul, res, :class=>:linked_files)
    end
    
    logins= %w{ town1 town2 town3 town4 town5 }
    
      logins.each do |login|
        user= User.find_by_login(login)
        
        eval("
          class OldSiteSection < OldSiteConnect
              set_table_name '#{login}_sections'
          end    
          class OldSitePage < OldSiteConnect
              set_table_name '#{login}_pages'
          end
          class OldSiteLinkedFiles < OldSiteConnect
              set_table_name '#{login}_linked_files'
          end
        ")
        
        #OldSitePage.find:first
        sections= OldSiteSection.find(:all,  :order=>"Prev_Id ASC")
        ids_set= Hash.new
        
        sections.each do |s|
          # Старый id страницы
          old_id= s.Page_Id
          # Старая страница
          basic_page= OldSitePage.find(old_id)

          # Найти файлы если они прикреплены к странице
          files= OldSiteLinkedFiles.find(:all, :conditions => ['Page_Id = ? and Linked = ?', old_id, 1])

          title= basic_page.Description.gsub("&gt;", '>').gsub("&lt;", '<').gsub("&quot;", "'")
          content= basic_page.Content.gsub("&gt;", '>').gsub("&lt;", '<').gsub("&quot;", "'")
          
          # Добавим список прикрепленных файлов
          (content = content + file_div(files) ) unless files.empty?
          
          # Поправим все пути
          content= content.gsub("./files/common/", "/uploads/files/#{login}/")
          content= content.gsub("./files/pages/", "/uploads/files/#{login}/")
          content= content.gsub("./files/#{login}/common/", "/uploads/files/#{login}/")
          content= content.gsub("./files/#{login}/pages/", "/uploads/files/#{login}/")

          page= Page.new( :user_id=>user.id,
                          :title=>title,
                          :content=>content
                         )
          page.save
          new_id= page.id
          # Добавить в список соответствий id
          # Если в спискок родителей имеет такой id
          page.move_to_child_of(Page.find(ids_set[s.Prev_Id])) if ids_set[s.Prev_Id]
          ids_set[old_id] = new_id
        end# sections.each do |s|
      end# logins.each do |login|
    end# db:import:start
  end# db:import
end#:db




  









