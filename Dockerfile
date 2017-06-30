FROM centos:latest

MAINTAINER david@codesmith.tech

RUN yum makecache && yum update -y

RUN yum install -y \
    unzip \
    gcc \
    libc-dev \
    make \
    autoconf \
    automake \
    libtool \
    bison \
    wget \
    ssmtp \
    libpcre3-dev \
    libxml2-devel.x86_64 \
    openssl-devel.x86_64 \
    libcurl-devel.x86_64 \
    libiodbc-devel.x86_64 \
    libmemcached-devel.x86_64 \
    zlib-devel.x86_64 \
    krb5-devel \
    pam-devel \
    gd-devel \
    libexif-devel \
    libjpeg-devel

RUN mkdir /php && \
    cd /php && \
    wget ftp://mcrypt.hellug.gr/pub/crypto/mcrypt/libmcrypt/libmcrypt-2.5.7.tar.gz && \
    tar xvzf libmcrypt-2.5.7.tar.gz && \
    cd libmcrypt-2.5.7 && \
    ./configure && \
    make && \
    make install && \
    rm -rf /php

RUN cd /opt && \
    wget http://ftp.ntua.gr/pub/net/mail/imap/c-client.tar.gz && \
    tar xvzf c-client.tar.gz && \
    cd imap-2007f && \
    ln -s /usr/lib64/openssl/engines/ /usr/local/ssl && \
    ln -s /usr/include/ /usr/local/ssl/include && \
    make lnp SSLTYPE=unix.nopwd EXTRACFLAGS=-fPIC && \
    mkdir lib && mkdir include && \
    cp c-client/*.c lib/ && \
    cp c-client/*.h include/ && \
    cp c-client/c-client.a lib/libc-client.a

RUN mkdir -p /php && \
    cd /php && \
    wget https://github.com/php/php-src/archive/PHP-7.1.6.zip && \
    unzip PHP-7.1.6.zip && \
    mv php-src-PHP-7.1.6 src && \
    cd /php/src && \
    ./buildconf --force && \
    ./configure -C \
    --with-config-file-path=/etc/php.ini \
    --with-config-file-scan-dir=/etc/php.d \
    --enable-bcmath \
    --enable-calendar \
    --enable-mbstring \
    --enable-xml \
    --enable-pcntl \
    --enable-ftp \
    --enable-zip \
    --enable-sockets \
    --enable-soap \
    --enable-exif \
    --enable-xdebug \
    --with-gd \
    --with-jpeg-dir=/usr/lib64 \
    --with-openssl \
    --without-pear \
    --with-imap=/opt/imap-2007f \
    --with-imap-ssl=/opt/imap-2007f \
    --with-openssl-dir=/usr/include/openssl \
    --with-curl=/usr/include/curl \
    --with-mcrypt=/usr/local/include \
    --with-zlib-dir=/usr/include \
    --with-pdo-mysql=mysqlnd \
    --with-mysqli && \
    make && \
    make install && \
    cp /php/src/php.ini-production /etc/php.ini && \
    mkdir -p /etc/php.d && \
    rm -rf /php

RUN wget https://pear.php.net/go-pear.phar && \
	mv go-pear.phar go-pear.php && \
	php go-pear.php && \
	rm go-pear.php

WORKDIR /app

RUN pecl install memcached && \
	echo "extension=memcached.so" > /etc/php.d/memcache.ini

RUN wget https://xdebug.org/files/xdebug-2.5.5.tgz && \
	tar -xzf xdebug-2.5.5.tgz && \
	cd xdebug-2.5.5 && \
	phpize && \
	./configure --enable-xdebug && \
	make && \
	make install && \
	echo "extension=xdebug.so" > /etc/php.d/xdebug.ini

RUN sed -i -e "s/expose_php\ =\ On/expose_php\ =\ Off/g" /etc/php.ini \
    && sed -i -e "s/\;error_log\ =\ php_errors\.log/error_log\ =\ \/var\/log\/php_errors\.log/g" /etc/php.ini \
    && sed -i -e "s/\;date\.timezone =/date\.timezone = Europe\/London/g" /etc/php.ini \
    && sed -i -e "s/display_errors = Off/display_errors = stderr/g" /etc/php.ini

RUN wget https://getcomposer.org/installer && \
	mv installer composer-installer.php && \
	php composer-installer.php --install-dir=/usr/local/bin --filename=composer && \
	rm -rf composer-installer.php

RUN unlink /etc/localtime && \
    ln -s /usr/share/zoneinfo/Europe/London /etc/localtime && \
    ln -s /usr/local/bin/php /usr/bin/php

RUN yum remove -y unzip gcc libc-dev make autoconf automake libtool bison wget
