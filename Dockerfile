FROM phr0ze/alpine-base:3.8

RUN echo ">> Install/configure apache and php7" && \
  apk add --no-cache apache2 php7 php7-apache2

RUN echo ">> Install apache/php" && apk add --no-cache \
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
  php7-zip && \
  echo ">> Configuring /etc/apache2/httpd.conf" && \
  sed -i 's|^\(ServerTokens\).*|\1 Prod|g' /etc/apache2/httpd.conf && \
  sed -i 's|^\(ServerRoot\).*|\1 /www|g' /etc/apache2/httpd.conf && \
  sed -i 's|^\(ServerSignature\).*|\1 Off|g' /etc/apache2/httpd.conf && \
  sed -i 's|/var/www/localhost/htdocs|/www/html|g' /etc/apache2/httpd.conf && \
  sed -i 's|\(Options\) Indexes|\1|g' /etc/apache2/httpd.conf && \
  sed -i 's|^\(.*DirectoryIndex index.html\).*|\1 index.php|g' /etc/apache2/httpd.conf && \
  sed -i 's|/var/www/localhost/cgi-bin|/www/cgi-bin|g' /etc/apache2/httpd.conf

# Run
EXPOSE 80 443
#WORKDIR /www
#ENTRYPOINT ["/usr/sbin/init"]
#CMD ["apache"]
