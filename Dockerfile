FROM phr0ze/alpine-base:3.8

RUN echo ">> Install/configure apache and php7" && \
  apk add --no-cache apache2 php7 php7-apache2

RUN echo ">> Install/configure php dependencies" && apk add --no-cache \
  ca-certificates \ # Common CA certificate PEM files
  php7 \            # The PHP7 language runtime engine
  php7-apache2 \    # Support for Apache2
  php7-ctype \      # Support for C types
  php7-curl \       # Support for cURL
  php7-dom \        # phpBB dependency
  php7-ftp \        # phpBB dependency 
  php7-gd \         # phpBB dependency
  php7-iconv \      # phpBB dependency
  php7-json \       # phpBB dependency
  php7-opcache \    # phpBB dependency
  php7-openssl \    # phpBB dependency
  php7-sqlite3 \    # phpBB dependency
  php7-tokenizer \  # phpBB dependency
  php7-xml \        # phpBB dependency
  php7-zlib \       # phpBB dependency
  php7-zip          # phpBB dependency

# Configure
COPY config/httpd.conf /etc/apache2/

# Run
EXPOSE 80
WORKDIR /www
ENTRYPOINT ["/usr/sbin/init"]
CMD ["apache"]
