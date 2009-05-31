module Site
  # Site::ADDRESS
  # Глобальные константы сайта
  ADDRESS = "http://localhost:3000"
  COOKIES_SCOPE = ".iv-schools.info" # авторизация действительна для всех поддоменов
  DOMAIN_DOES_NOT_EXIST = 'Вы пытаетесь обратиться к разделу сайта, которого не существует.<br />Пожалуйста, перейдите по ссылке <a href="'+Site::ADDRESS+'">iv-schools.ru</a>'
  
  ERROR = 'Ошибка'
  ERRORS = 'Ошибки'
  NOTICE = 'Уведомление'
  SYSTEM_NOTICE= 'Системное уведомление'
  SYSTEM_WARNING= 'Предупреждение'
  SECTION_NOT_FOUND = "Не удалось обнаружить запрошенный раздел<br />Идентификатор раздела: "
end