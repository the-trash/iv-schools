module Project
  # Project::AVATARA_URL
  ADDRESS = "http://poweruser.ru"
  COOKIES_SCOPE = ".poweruser.ru" # авторизация действительна для всех поддоменов
  AVATARA_DEFAULT = "/uploads/:attachment/default/:style/missing.jpg"
  AVATARA_URL = "/uploads/:attachment/:login/:style/:filename"
  FILE_URL = "/uploads/files/:holder_login/:filename"
end