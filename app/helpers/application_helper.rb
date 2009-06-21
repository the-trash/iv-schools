# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  # Вывод ошибок валидации данного объекта
  def object_errors(obj)
    # Если переданный объект пустой или пустое поле ошибки
    (obj.nil? || obj.errors.empty?) ? (return nil) : nil
    res= ""

    obj.errors.each do |name, value|
      res<< content_tag(:li, value)
    end #obj.errors.each
    
    res= content_tag :ul, res
    err_header= ((obj.errors.size>1) ? Site::ERRORS : Site::ERROR)
    res= content_tag(:h3, err_header)+res
    res= content_tag :div, res, :class=>:error
    res= content_tag :div, res, :class=>:system_messages
  end
  
  # Вывод стандартных флеш сообщений
  def app_flash(flash)
    res= ''
    # Если переданный объект пустой
    flash.is_a?(Hash) ? nil : (return nil)
    
    if flash[:notice]
      flash_= ''
      flash_= content_tag(:li, flash[:notice])
      flash_= content_tag :ul, flash_
      flash_= content_tag(:h3, Site::NOTICE)+flash_
      flash_= content_tag :div, flash_, :class=>:notice
      flash_= content_tag :div, flash_, :class=>:system_messages
      # Обнулим флеш - иногда он имеет свойство проявляться
      flash[:notice]= nil
      res+= flash_
    end
    
    if flash[:warning]
      warn_= ''
      warn_= content_tag(:li, flash[:warning])
      warn_= content_tag :ul, warn_
      warn_= content_tag(:h3, Site::SYSTEM_WARNING)+warn_
      warn_= content_tag :div, warn_, :class=>:warning
      warn_= content_tag :div, warn_, :class=>:system_messages
      # Обнулим флеш - иногда он имеет свойство проявляться
      flash[:warning]= nil
      res+= warn_
    end
    
    unless flash[:system_warnings].empty?
      sys_warn_= ''
      flash[:system_warnings].each do |sw|
        sys_warn_+= content_tag(:li, sw)
      end
      
      sys_warn_= content_tag :ul, sys_warn_
      sys_warn_= content_tag(:h3, Site::SYSTEM_NOTICE)+sys_warn_
      sys_warn_= content_tag :div, sys_warn_, :class=>:warning
      sys_warn_= content_tag :div, sys_warn_, :class=>:system_messages
      # Обнулим флеш - иногда он имеет свойство проявляться
      flash[:warning]= nil
      res+= sys_warn_
    end
    res
  end #app_flash


  #-------------------------------------------------------------------------------------------------------
  # Nested Set View Helpers
  #-------------------------------------------------------------------------------------------------------
      
  # Берем дерево и узел в нем
  # Рисуем узел, и удаляем его из дерева
  # Рисуем рекурсивно все элементы дерева, у которых такой же parent_id удаленного узела, и удаляем их из дерева.
  # Тем самым при каждой рекурсии облегчаем дерево
  # Отрисовываем элементы
  # Наиболее общий действующий хелпер отрисовки дерева
  def print_node_and_childs_and_destroy_them! tree, node
    res= link_to(node.title, '#')
    parent_id= node.id  # Получим id узла, что бы позже найти его дочерние элементы
    tree.delete(node)   # Удаляем узел из дерева
    # Отображение дочерних
    child_res= ''
    # Выбираем дочерние элементы Удаленного узла в дереве
    childs= tree.select{ |elem| elem.parent_id == parent_id }
    # Делаем все тоже самое для дочерних
    childs.each{ |elem| child_res << print_node_and_childs_and_destroy_them!(tree, elem) }
    child_res= child_res.blank? ? '' :(content_tag :ul, child_res)
    res= content_tag :li, (res + child_res)
    res # Вернуть результат
  end
  
  # Берем дерево и узел в нем
  # Рисуем узел, и удаляем его из дерева
  # Рисуем рекурсивно все элементы дерева, у которых такой же parent_id удаленного узела, и удаляем их из дерева.
  # Тем самым при каждой рекурсии облегчаем дерево
  # Отрисовываем элементы
  # Отрисовка карты сайта
  def map_and_destroy! tree, node, root= false
    # Формируем ссылку
    res= link_to node.title, page_path(node)
    # Если корневой раздел - применяем класс
    res= content_tag :li, res, :class=>(root ? 'root' : '')
    
    parent_id= node.id  # Получим id узла, что бы позже найти его дочерние элементы
    tree.delete(node)   # Удаляем узел из дерева
    
    # Отображение дочерних
    child_res= ''
    # Выбираем дочерние элементы Удаленного узла в дереве
    childs= tree.select{ |elem| elem.parent_id == parent_id }
    # Делаем все тоже самое для дочерних
    childs.each{ |elem| child_res << map_and_destroy!(tree, elem) }
    # Если дочерние 0 не пустые - обернем их в ul, а его в li
    child_res= child_res.blank? ? '' : (content_tag :li, (content_tag :ul, child_res))
    # Вернуть результат
    res + child_res
  end
  #-------------------------------------------------------------------------------------------------------
  # ~Nested Set View Helpers
  #-------------------------------------------------------------------------------------------------------
  
end
