FROM phusion/baseimage:latest

MAINTAINER Ralf Geschke <ralf@kuerbis.org>


ENV DEBIAN_FRONTEND noninteractive    

RUN apt-get update && \
    apt-get install -y --no-install-recommends wget \
    build-essential software-properties-common curl patch gawk sudo git openssl automake autoconf libtool \
    libyaml-dev bison pkg-config libc-dev libc6-dev ncurses-dev pkg-config libffi-dev libncurses5-dev make gcc g++ \
    cron dh-python distro-info-data file fontconfig-config libgdbm-dev libsqlite3-dev sqlite3  libffi-dev  \
    zip libssl-dev libreadline6 libreadline6-dev zlib1g zlib1g-dev openssh-client \
    fonts-dejavu-core geoip-database ifupdown iproute2 isc-dhcp-client isc-dhcp-common \
    libatm1 libbsd0 libdns-export162 libedit2 libevent-2.0 libevent-core-2.0 libevent-extra-2.0 \
    libexpat1 libfontconfig1 libfreetype6 libgd3 libgeoip1 libicu55 libisc-export160 libjbig0 \
    libjpeg-turbo8 libjpeg8 libmagic1 libmnl0 libmpdec2 libpng12-0 libpopt0 libpq5 libpq-dev libreadline5 \
    libsensors4 libtiff5 libvpx3 libx11-6 libx11-data libxau6 libxcb1 libxdmcp6 libxml2 libxpm4 \
    libxslt-dev libxml2-dev libxtables11 logrotate lsb-release mime-support sgml-base ssl-cert sysstat \
    ucf xml-core xz-utils supervisor libgmp-dev \
    imagemagick nginx \
    && mkdir -p /var/log/supervisor 

# install postfix
RUN echo "postfix postfix/main_mailer_type string Internet site" > /root/preseed.txt \
    && debconf-set-selections /root/preseed.txt \
    && apt-get --no-install-recommends install -q -y libsasl2-modules postfix \
    && rm -rf /var/lib/apt/lists/*
    

RUN useradd zammad -m -d /opt/zammad -s /bin/bash && echo "export RAILS_ENV=production" >> /opt/zammad/.bashrc

USER zammad

#RUN cd /opt/zammad && wget https://ftp.zammad.com/zammad-latest.tar.gz && tar -xzf zammad-latest.tar.gz
RUN cd /opt/zammad && wget https://ftp.zammad.com/zammad-1.1.2.tar.gz && tar -xzf zammad-1.1.2.tar.gz
#RUN cd /opt/zammad && git clone https://github.com/zammad/zammad.git zmd && cp -r zmd/* . \
#    && rm -Rf zmd

WORKDIR /opt/zammad

RUN mkdir /opt/zammad/initdata

RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 && \
  \curl -sSL https://get.rvm.io | bash -s stable



RUN /bin/bash -l -c "gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 && \
    curl -L https://get.rvm.io | bash -s stable && \
    source /opt/zammad/.rvm/scripts/rvm && \
    echo \"source /opt/zammad/.rvm/scripts/rvm\" >> /opt/zammad/.bashrc && \
    echo \"rvm --default use 2.3.1\" >> /opt/zammad/.bashrc && \
    rvm install 2.3.1 && \
    gem install bundler &&\ 
    bundle install --without test development mysql"

USER root 

COPY config/database.yml /opt/zammad/config/database.yml
COPY config/zammad.conf /etc/nginx/sites-available/
COPY config/elasticsearch.conf /etc/nginx/sites-available/
COPY config/master.cf /etc/postfix/
RUN ln -s /etc/nginx/sites-available/zammad.conf /etc/nginx/sites-enabled/zammad.conf 
RUN ln -s /etc/nginx/sites-available/elasticsearch.conf /etc/nginx/sites-enabled/elasticsearch.conf


COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

COPY start.sh / 
COPY init.sh /

RUN chmod 755 /start.sh /init.sh

EXPOSE 80/tcp

ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["app:start"]

