FROM phusion/baseimage:0.9.22

# Phusion setup
ENV HOME /root
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

CMD ["/sbin/my_init"]

# Set terminal to non-interactive
ENV DEBIAN_FRONTEND=noninteractive

# Nginx-PHP Installation
RUN add-apt-repository -y ppa:ondrej/php && apt-get update -y
RUN apt-get install -y ntp nginx php5.6-mysql php5.6-opcache php5.6-readline php5.6-soap php5.6-xml php5.6-xsl php5.6-zip \
        php5.6-bcmath php5.6-cli php5.6-common php5.6-curl php5.6-fpm php5.6-gd php5.6-intl php5.6-json php5.6-mbstring php5.6-mcrypt

# Create new symlink to UTC timezone for localtime
RUN unlink /etc/localtime
RUN ln -s /usr/share/zoneinfo/Europe/Malta /etc/localtime

# Add build script
RUN mkdir -p /root/setup
ADD build/setup.sh /root/setup/setup.sh
RUN chmod +x /root/setup/setup.sh
RUN (cd /root/setup/; /root/setup/setup.sh)

# Copy files from repo
ADD build/default /etc/nginx/sites-available/default
ADD build/nginx.conf /etc/nginx/nginx.conf
ADD build/php-fpm.conf /etc/php/5.6/fpm/php-fpm.conf
ADD build/www.conf /etc/php/5.6/fpm/pool.d/www.conf
ADD build/.bashrc /root/.bashrc

# Add startup scripts for services
ADD build/nginx.sh /etc/service/nginx/run
RUN chmod +x /etc/service/nginx/run

ADD build/phpfpm.sh /etc/service/phpfpm/run
RUN chmod +x /etc/service/phpfpm/run

ADD build/ntp.sh /etc/service/ntp/run
ADD build/ntp.conf /etc/ntp.conf
RUN chmod +x /etc/service/ntp/run

# Set WWW public folder
RUN mkdir -p /var/www/public
ADD www/index.php /var/www/public/index.php

RUN chown -R www-data:www-data /var/www
RUN chmod -R 755 /var/www

# Set terminal environment
ENV TERM=xterm

# Port and settings
EXPOSE 80

# Cleanup apt and lists
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
