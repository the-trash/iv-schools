#
# docker build -t iamteacher/iv_schools:webapp.amd64 -f IvSchools.Dockerfile .
# docker run -ti iamteacher/iv_schools:webapp.amd64 bash

# TODO:
# ruby ree 1.8.7
# gem 1.5.3
# bundler 1.3.5
# rake 0.8.7
# ImageMagick 6.8.9-9 Q16 x86_64 2016-11-26

FROM instructure/rvm:latest

USER root

# apt-cache search libssl
RUN apt-get update
RUN apt-get install --force-yes -y wget

RUN apt-get --force-yes -y remove libssl-dev
RUN apt-get --force-yes -y remove libcurl4-openssl-dev
RUN apt autoremove --force-yes -y

# RUN apt-get install --force-yes -y sudo
# RUN usermod -aG sudo docker

WORKDIR /tmp

# http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/

RUN wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0-dev_1.0.2n-1ubuntu5.10_amd64.deb
RUN wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5.10_amd64.deb

RUN dpkg -i libssl1.0.0_1.0.2n-1ubuntu5.10_amd64.deb
RUN dpkg -i libssl1.0-dev_1.0.2n-1ubuntu5.10_amd64.deb

RUN wget http://snapshot.debian.org/archive/debian/20190501T215844Z/pool/main/g/glibc/multiarch-support_2.28-10_amd64.deb

RUN wget http://launchpadlibrarian.net/162702614/libmysqlclient18_5.5.35-0ubuntu1_amd64.deb
RUN wget http://launchpadlibrarian.net/162702617/libmysqlclient-dev_5.5.35-0ubuntu1_amd64.deb
RUN wget http://launchpadlibrarian.net/302797791/mysql-common_5.8+1.0.2ubuntu1_all.deb

RUN dpkg -i multiarch-support*.deb

RUN dpkg -i mysql-common_5.8+1.0.2ubuntu1_all.deb
RUN dpkg -i libmysqlclient18_5.5.35-0ubuntu1_amd64.deb
RUN dpkg -i libmysqlclient-dev_5.5.35-0ubuntu1_amd64.deb

RUN chown docker:docker /home

USER docker
WORKDIR /home
SHELL ["/bin/bash", "-l", "-c"]

# rvm list known
RUN rvm autolibs enable
RUN rvm install ree-1.8.7-2012.02
RUN rvm use --default ree-1.8.7-2012.02

RUN gem install bundler       -v 1.3.5 --no-document --verbose
RUN gem install rake          -v 0.8.7 --no-document --verbose

RUN gem install mysql         -v 2.8.1  --no-document --verbose
RUN gem install nokogiri      -v 1.5.2  --no-document --verbose
RUN gem install sanitize      -v 2.0.3  --no-document --verbose
RUN gem install RedCloth      -v 4.2.9  --no-document --verbose
RUN gem install rmagick       -v 2.14.0 --no-document --verbose

RUN gem install rails         -v 2.3.4 --no-document --verbose
RUN gem install haml          -v 3.1.4 --no-document --verbose
RUN gem install paperclip     -v 2.3.1.1 --no-document --verbose
RUN gem install i18n          -v 0.6.0 --no-document --verbose
RUN gem install state_machine -v 1.1.2 --no-document --verbose
RUN gem install subdomain-fu  -v 1.0.0.beta2 --no-document --verbose
RUN gem install russian       -v 0.6.0 --ignore-dependencies --no-document --verbose
RUN gem install raindrops     -v 0.13.0 --no-document --verbose
RUN gem install unicorn       -v 4.8.2 --no-document --verbose

RUN gem update --system 1.5.3

USER docker
RUN mkdir /home/rails
WORKDIR /home/rails
