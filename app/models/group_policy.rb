class GroupPolicy < ActiveRecord::Base
# GroupPolicy - надстройка над Моделью Role, обеспечивающая граничение по времени и количеству фактов доступа к функции
# Привязано к конкретной роли.
# -Обеспечивает доступ группы к классу объектов
# (Группа пользователей может редактировать все деревья страниц проекта с ограничением по времени и колву фактов доступа)
# id | role_id | section | action | value | start_at | finish_at | counter | max_count
# Для конкретного пользователя sql запросом для данной роли выбирается весь массив настроек
# формируется хеш массив, при необходимости проверки - сопостовляется и проверяется по времени, количеству фактов доступа
# при необходимости, выполняется инкрементация счетчика в БД на заданное кол-во единиц
# Интегрировано в интерфейс редактирования модели Role

  belongs_to :role # Надстройки Группавой политики связаны с конкретной ролью

end
