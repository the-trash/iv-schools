$ docker build -t iamteacher/iv_schools:webapp.amd64 -f IvSchools.Dockerfile ../
$ docker compose -f ./dev.docker-compose.yml up -d

$ docker ps
  iv-schools-rails-1
  iv-schools-mysql-1

# login as `docker` user (id: 1000)
$ docker exec -ti iv-schools-rails-1 /bin/bash -l

$ cd /home/rails
$ script/console

```
  https://guides.rubyonrails.org/v2.3/active_record_querying.html#selecting-specific-fields
```

$ script/server -b 0.0.0.0 -p 3000

### Server

```
export DOCKER_USER_ID=$(id -u)
export DOCKER_GROUP_ID=$(id -g)
```

$ docker pull mysql
$ docker pull iamteacher/iv_schools:webapp.amd64

$ docker compose -f prod.docker-compose.yml up mysql -d
$ docker exec -ti iv-schools-mysql-1 bash

> mysql -u rails -h localhost -pqwerty
> mysql -urails -h localhost -pqwerty  iv_schools < shared/iv-schools.ru.iv_schools.2022_12_11_09_25.mysql.sql

$ docker compose -f prod.docker-compose.yml up -d

$ docker exec -ti -u 9999:9999 iv-schools-rails-1 bash -l
$ script/server -e production -b 0.0.0.0 -p 3000 -d
