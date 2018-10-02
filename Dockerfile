FROM phr0ze/alpine-base:3.8

# Environment variables
ENV SERVER_NAME=localhost
ENV TIME_ZONE=America/Denver

# Installation/Customization
RUN echo ">> Install httpd/php" && \
  apk add --no-cache \
    apache2 \
    apache2-utils \
    ca-certificates \
    php7 \
    php7-apache2 \
    php7-ctype \
    php7-curl \
    php7-dom \
    php7-ftp \
    php7-gd \
    php7-iconv \
    php7-json \
    php7-opcache \
    php7-openssl \
    php7-sqlite3 \
    php7-tokenizer \
    php7-xml \
    php7-zlib \
    php7-zip \
  && \
  echo ">> Relocate apache httpd root" && \
    mv /var/www / && \
    mv /www/localhost/cgi-bin /www/cgi && \
    mv /www/localhost/htdocs /www/html && \
    rm /www/html/* && rmdir /www/localhost && \
    mkdir /run/apache2 && chown apache: /run/apache2 && \
  \
  echo ">> Configuring /etc/apache2/httpd.conf" && \
    sed -i 's|^\(ServerTokens\).*|\1 Prod|g' /etc/apache2/httpd.conf && \
    sed -i 's|^\(ServerRoot\).*|\1 /www|g' /etc/apache2/httpd.conf && \
    sed -i 's|^\(ServerSignature\).*|\1 Off|g' /etc/apache2/httpd.conf && \
    sed -i 's|/var/www/localhost/htdocs|/www/html|g' /etc/apache2/httpd.conf && \
    sed -i 's|\(Options\) Indexes|\1|g' /etc/apache2/httpd.conf && \
    sed -i 's|/var/www/localhost/cgi-bin|/www/cgi|g' /etc/apache2/httpd.conf && \
    sed -i 's|^\(.*DirectoryIndex index.html\).*|\1 index.php|g' /etc/apache2/httpd.conf && \
    echo '    AddType application/x-httpd-php .php' >> conf && \
    echo '    AddType application/x-httpd-php-source .phps' >> conf && \
    sed -i '/AddType application\/x-gzip .gz .tgz/r conf' /etc/apache2/httpd.conf && rm conf && \
    sed -i 's|^\(ErrorLog\).*|\1 /dev/stderr|g' /etc/apache2/httpd.conf && \
    sed -i 's|\(.* CustomLog\).*|\1 /dev/stdout combined|g' /etc/apache2/httpd.conf && \
  \
  echo ">> Configuring /etc/php/php.ini" && \
    sed -i 's|^\(upload_max_filesize\).*|\1 = 200M|g' /etc/php7/php.ini && \
    sed -i 's|^\(expose_php\).*|\1 = Off|g' /etc/php7/php.ini && \
    sed -i 's|^\(max_execution_time\).*|\1 = 6000|g' /etc/php7/php.ini && \
    sed -i 's|^\(max_input_time\).*|\1 = 6000|g' /etc/php7/php.ini && \
    sed -i 's|^\(post_max_size\).*|\1 = 210M|g' /etc/php7/php.ini

# Config
COPY start /usr/bin/
COPY config/index.php /www/html/

# Run
EXPOSE 80
WORKDIR /www
CMD ["start"]
