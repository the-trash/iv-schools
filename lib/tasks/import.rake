# Базовые роли пользователей
namespace :db do
  namespace :import do
  
    # rake db:import:start
    desc 'import data form ivschools'
    task :start => :environment do
    class IvSchoolsPageConnect< ActiveRecord::Base
        establish_connection(
          :adapter  => "mysql",
          :host     => "localhost",
          :username => "root",
          :password => "",
          :database => "ivschools",
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
    
    logins= %w{ iv36 iv43 kohma5 kohma6 kohma7 kohma5vecher }
    
      logins.each do |login|
        user= User.find_by_login(login)
        
        eval("
          class IvSchoolsSection < IvSchoolsPageConnect
              set_table_name '#{login}_sections'
          end    
          class IvSchoolsPage < IvSchoolsPageConnect
              set_table_name '#{login}_pages'
          end
          class IvSchoolsLinkedFiles < IvSchoolsPageConnect
              set_table_name '#{login}_linked_files'
          end
        ")
        
        #IvSchoolsPage.find:first
        sections= IvSchoolsSection.find(:all,  :order=>"Prev_Id ASC")
        ids_set= Hash.new
        
        sections.each do |s|
          # Старый id страницы
          old_id= s.Page_Id
          # Старая страница
          basic_page= IvSchoolsPage.find(old_id)
          # Найти файлы если они прикреплены к странице
          files= IvSchoolsLinkedFiles.find(:all, :conditions => ['Page_Id = ? and Linked = ?', old_id, 1])
          
          # Создали новую
          zip= "#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}"
          while Page.find_by_zip(zip)
            zip= "#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}-#{(1000..9999).to_a.rand}"
          end
          
          title= basic_page.Description.gsub("&gt;", '>').gsub("&lt;", '<').gsub("&quot;", "'")

          content= basic_page.Content.gsub("&gt;", '>').gsub("&lt;", '<').gsub("&quot;", "'")
          (content = content + file_div(files) ) unless files.empty?
          
          content= content.gsub("./files/common/", "/uploads/files/#{login}/")
          content= content.gsub("./files/pages/", "/uploads/files/#{login}/")
          
          content= content.gsub("./files/#{login}/common/", "/uploads/files/#{login}/")
          content= content.gsub("./files/#{login}/pages/", "/uploads/files/#{login}/")

          page= Page.new( :user_id=>user.id,
                          :zip=>zip,
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
    end# rake db:roles:create
  end#:roles
end#:db