module Message
  # Message::LOGINED
  # Сообщения генерируемые системой
	
	#User
	USER_LOGINED = "Спасибо за регистрацию в системе iv-schools.ru"
  USER_CANT_CREATE = "Не удалось создать пользователя"
  USER_ENTERED = "Выполнен вход в систему iv-schools.ru"
  USER_LOGOUTED = "Выход из системы iv-schools.ru успешно выполнен"
  USER_ENTER_ERROR= "Ошибка входа в систему iv-schools.ru. Возможно Логин или Пароль указаны не верно"
  
  #Server
  SERVER_ERROR= "Ошибка стороны сервера"
  DATA_ARE_REQUIRED= "Для выполнения действия требуются дополнительные данные"
  
  #SETTING
  SETTING_EMPTY_SECTION_NAME= "Не установлено имя раздела прав"
  SETTING_SECTION_WRONG_NAME= "Некорректное имя раздела прав"
  SETTING_SECTION_RULE_WRONG_NAME= "Некорректное имя правового правила в разделе: "
  SETTING_SECTION_DESTROY= "Раздел прав удален"
  SETTING_SECTION_IS_NOT_HASH= "Раздел прав не является Хешем. Высока вероятность повреждения базы данных. Обратитесь к разработчику"
  SETTING_SECTION_HASNT_RULE= "Раздел не содержит указанного правила"
  SETTING_ARRAY_FORMING_ERROR= "Ошибка формирования правового массива. Высока вероятность повреждения базы данных. Обратитесь к разработчику"
  SETTING_SECTION_EXISTS= "Раздел прав уже существует"
  SETTING_SECTION_CREATE= "Раздел прав создан"
  SETTING_SECTION_RULE_CREATE= "Правило успешно создано и активировано"
  SETTING_SECTION_RULE_DESTROY= "Правило успешно удалено"
  SETTING_NON_EXISTS= "Раздел прав не существует"
  SETTING_TRY_TO_CREATE_SECTION= "Попробуйте сперва создать раздел прав"
  SETTING_DESTROY_CONFIRM= "Вы уверены что хотите удалить раздел прав со всеми вложенными правилами доступа: "
end