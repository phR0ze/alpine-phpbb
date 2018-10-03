FROM phr0ze/alpine-base:3.8

# Environment variables
ENV USERID=33
ENV USERNAME=http
ENV SERVER_ROOT=/www
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
  echo ">> Change apache user/group and relocate root" && \
    mv /var/www ${SERVER_ROOT} && \
    mv ${SERVER_ROOT}/localhost/cgi-bin ${SERVER_ROOT}/cgi && \
    mv ${SERVER_ROOT}/localhost/htdocs ${SERVER_ROOT}/http && \
    rm ${SERVER_ROOT}/http/* && rmdir ${SERVER_ROOT}/localhost && \
    deluser xfs && deluser apache && \
    addgroup -g ${USERID} ${USERNAME} && \
    adduser -u ${USERID} -G ${USERNAME} -g 'httpd' -h ${SERVER_ROOT} -s /sbin/nologin -D ${USERNAME} && \
    mkdir /run/apache2 && chown ${USERNAME}: /run/apache2 && \
  \
  echo ">> Configuring /etc/apache2/httpd.conf" && \
    sed -i 's|^\(ServerTokens\).*|\1 Prod|g' /etc/apache2/httpd.conf && \
    sed -i "s|^\(ServerRoot\).*|\1 ${SERVER_ROOT}|g" /etc/apache2/httpd.conf && \
    sed -i 's|^\(ServerSignature\).*|\1 Off|g' /etc/apache2/httpd.conf && \
    sed -i "s|^\(User\) apache.*|\1 ${USERNAME}|g" /etc/apache2/httpd.conf && \
    sed -i "s|^\(Group\) apache.*|\1 ${USERNAME}|g" /etc/apache2/httpd.conf && \
    sed -i "s|/var/www/localhost/htdocs|${SERVER_ROOT}/http|g" /etc/apache2/httpd.conf && \
    sed -i 's|\(Options\) Indexes|\1|g' /etc/apache2/httpd.conf && \
    sed -i "s|/var/www/localhost/cgi-bin|${SERVER_ROOT}/cgi|g" /etc/apache2/httpd.conf && \
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
COPY config/index.php $SERVER_ROOT/http/

# Run
EXPOSE 80
WORKDIR $SERVER_ROOT
CMD ["start"]
