# Создал фабрику для групповой политики для объекта (PersonalResourcePolicy)
Factory.define :group_resource_policy do |prp| end 
  
###################################################################################################
# Групповая политика к ресурсу
###################################################################################################

# Политика для данного пользователя
Factory.define  :page_manager_group_resource_policy, :class => PersonalResourcePolicy do |r|
  r.section     'pages'
  r.action      'manager'
  r.value       true
  r.start_at    DateTime.now
  r.finish_at(  DateTime.now + 3.days)
  r.counter     5
  r.max_count   15
end

# Политика для данного пользователя
Factory.define  :page_tree_group_resource_policy, :class => PersonalResourcePolicy do |r|
  r.section     'pages'
  r.action      'tree'
  r.value       true
  r.start_at    DateTime.now
  r.finish_at(  DateTime.now + 1.days)
  r.counter     2
  r.max_count   11
end

# Политика для данного пользователя
Factory.define  :profile_edit_group_resource_policy, :class => GroupResourcePolicy do |r|
  r.section     'profile'
  r.action      'edit'
  r.value       true
  r.start_at    DateTime.now-1.day
  r.finish_at   DateTime.now + 1.days
  r.counter     2
  r.max_count   11
end

# Групповая политика для данного пользователя
Factory.define  :page_tree_group_resource_policy_unlimited, :class => GroupResourcePolicy do |r|
  r.section     'pages'
  r.action      'tree'
  r.value       true
end

Factory.define  :page_manager_group_resource_policy_unlimited, :class => GroupResourcePolicy do |r|
  r.section     'pages'
  r.action      'manager'
  r.value       true
end