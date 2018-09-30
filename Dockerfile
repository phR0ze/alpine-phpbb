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
  php7-zip
#echo ">> Configure apache/php" && \
#sed -i 's|^DocumentRoot ".*|DocumentRoot "/web/html"|g' /etc/apache2/httpd.conf 

# Run
EXPOSE 80 443
#WORKDIR /www
#ENTRYPOINT ["/usr/sbin/init"]
#CMD ["apache"]
