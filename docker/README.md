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
