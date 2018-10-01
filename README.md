# alpine-php
Docker container for a php deployment

## Overview
Built off of Alpine Linux which is the defacto standard for production containers.

## Configuration
* httpd.conf

```bash
# Convey the least amount of server information in responses
sed -i 's|^\(ServerTokens\).*|\1 Prod|g' /etc/apache2/httpd.conf && \

# Change where the files are hosted from for ease of access in container
sed -i 's|^\(ServerRoot\).*|\1 /www|g' /etc/apache2/httpd.conf && \

# Reduce information returned about server
sed -i 's|^\(ServerSignature\).*|\1 Off|g' /etc/apache2/httpd.conf && \

# Use our new path for html content
sed -i 's|/var/www/localhost/htdocs|/www/html|g' /etc/apache2/httpd.conf && \

# Deny index listing by default
sed -i 's|\(Options\) Indexes|\1|g' /etc/apache2/httpd.conf && \

# Allow php index files to be read
sed -i 's|^\(.*DirectoryIndex index.html\).*|\1 index.php|g' /etc/apache2/httpd.conf && \

# Use our new path for cgi content as well
sed -i 's|/var/www/localhost/cgi-bin|/www/cgi-bin|g' /etc/apache2/httpd.conf
```

### MPM Prefork
https://httpd.apache.org/docs/2.4/mod/prefork.html

Using the ***mpm_prefork_module*** implements a non-threaded, pre-forking web server. Each server
process may answer incoming requests. The parent process manages the size of the process pool.
Apache httpd always tries to maintain several spare or idle server processes ready to serve incoming
requests. Apache httpd is very self-regulating so most sites do not need to adjust the specifics of
***mpm_prefork***. 

```bash
LoadModule mpm_prefork_module modules/mod_mpm_prefork.so
<IfModule mpm_prefork_module>
    StartServers           5

    # Defaults to 5
    MinSpareServers        5

    # Defaults to 10
    MaxSpareServers        5

    # Defaults to 256
    MaxRequestWorkers    100

    # Defaults to 0
    MaxConnectionsPerChild 0
</IfModule>
```

## Build
```bash
git clone https://github.com/phR0ze/alpine-php
cd alpine-php
docker build -t alpine-php .
```

## Debug
```bash
docker run --rm -it alpine-php bash
```

## Run
```bash
# --init runs a super light weight init inside the container that forwards signals and reaps
# processes which protects you from zombies eating up all resources
docker run --init
```
