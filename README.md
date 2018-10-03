# alpine-phpbb
Docker container for a phpbb deployment

### Table of Contents
* [Deployment](#deployment)
  * [Build and Stage](#build-and-stage)
  * [Debug](#debug)
  * [Run](#run)
* [Upgrading phpBB](#upgrading-phpbb)
  * [Backup Current Deployment](#backup-current-deployment)
  * [Upgrade Minor Version](#upgrade-minor-version)
* [Configuration](#configuration)
  * [Packages](#packges)
  * [/etc/apache2/httpd.conf](#etc-apache2-httpd-conf)
    * [PHP7 Modules](#php7-modules)
    * [MPM Prefork Module](#mpm-prefork-module)
  * [/etc/php7/php.ini](#etc-php7-php-ini)

## Deployment <a name="deployment"/></a>
Built off of Alpine Linux which is the defacto standard for production containers.

### Build and Stage <a name="build-and-stage"/></a>
```bash
# Build your image with the correct tag
git clone https://github.com/phR0ze/alpine-phpbb
cd alpine-phpbb
docker build -t alpine-phpbb .

# Login to docker hub if you haven't already
docker login

# Tag your docker image for release
docker tag alpine-phpbb phr0ze/alpine-phpbb:latest
docker push phr0ez/alpine-phpbb:latest
```

### Debug <a name="debug"/></a>
```bash
# Run your apache container in one terminal
docker run --rm --name phpbb -e SERVER_NAME=localhost -p 80:80 phr0ze/alpine-phpbb

# Attach to your apache container in another terminal
docker exec -it phpbb bash
```

### Run <a name="run"/></a>
```bash
docker run -d --name phpbb -p 80:80 -v /path/to/content:/www phr0ze/alpine-phpbb
```

## Upgrading phpBB <a name="upgrading-phpbb"/></a>
Choose a location to store your phpbb deployment. I'll be using ***/srv*** for this example and
running on ***cyberlinux*** so something are specific to that distro.

### Backup Current Deploymet <a name="backup-current-deployment"/></a>
```bash
# Create a tarball of current deployment
cd /srv
sudo tar cvzf http-2018.10.2.tar.gz http

# Backup tarball to a backup location
sudo mv http-2018.10.2.tar.gz ~/Downloads/Backup
```

### Upgrade Minor Version e.g. 3.2.1 to 3.2.3 <a name="upgrade-minor-version"/></a>
1. Prepare Current Deployment  
 a. [Backup Current Deployment](#backup-current-deployment)  
 b. Navigate to the ***ACP >Board Settings*** and make sure ***prosilver*** is the theme  
 c. Remove ***vendor*** and ***cache***  
 ```bash
 cd /srv
 sudo rm -rf http/{vendor,cache}
 ```
2. Prepare latest phpBB for deployment
  ```bash
  # Navigate to https://www.phpbb.com/downloads/ and determine latest version
  sudo wget https://www.phpbb.com/files/release/phpBB-3.2.3.zip

  # Extract phpbb zip and rename
  sudo unzip phpBB-3.2.3.zip

  # Remove new place holders and set ownership
  sudo rm -rf phpBB3/config.php phpBB3/{images,files,store} phpBB3/ext/phpbb/viglink
  sudo chown -R http: phpBB3
  ```
3. Deploy upgraded new bits
  ```bash
  # Copy phpBB3 contents to deployment location
  sudo copy -r phpBB3/* http
  ```
4. Update the datbase
  ```bash
  docker run --rm --name phpbb -v /srv/http:/www/http phr0ze/alpine-phpbb bash
  ```

## Configuration <a name="configuration"/></a>

### Packages <a name="packages"/></a>
* ***apache2*** - 
* ***apache2-utils*** - 
* ***ca-certificates*** - 
* ***php7*** - 
* ***php7-apache2*** - 
* ***php7-ctype*** - 
* ***php7-curl*** - 
* ***php7-dom*** - 
* ***php7-ftp*** - 
* ***php7-gd*** - graphics support for phpBB
* ***php7-iconv*** - 
* ***php7-json*** - 
* ***php7-opcache*** - 
* ***php7-openssl*** - 
* ***php7-sqlite3*** - sqlite3 database support for phpBB
* ***php7-tokenizer*** - 
* ***php7-xml*** - 
* ***php7-zlib*** - 
* ***php7-zip*** - 

### /etc/apache2/httpd.conf <a name="etc-apache2-httpd-conf"/></a>

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

#### PHP7 Modules <a name="php7-modules"/></a>
The ***mod_php7*** modules is loaded by default no ***httpd.conf*** setting is required

#### MPM Prefork Module <a name="mpm-prefork-module"/></a>
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

### /etc/php7/php.ini <a name="etc-php7-php-ini"/></a>
Turns out that PHP7 automatically loads any extensions that are installed so there is no need to
enable them in the config using the nify ***/etc/php7/conf.d*** entries


