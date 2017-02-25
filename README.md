* ruby-1.8.7-p374
* gem 1.5.3
* rake 0.8.7
* bundler 1.3.5

gem update --system 1.5.3
gem install rake -v 0.8.7
gem install bundler -v 1.3.5

mysql -u the-teacher -pqwerty iv_schools_dev < ~/DUMPS/
