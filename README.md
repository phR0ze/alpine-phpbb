# alpine-phpbb
Docker container for a phpbb deployment

### Table of Contents
* [Deployment](#deployment)
  * [Run Current Deployment](#run-current-deployment)
  * [Backup Current Deployment](#backup-current-deployment)
  * [Restore Current Deployment](#backup-current-deployment)
  * [Upgrade Minor Version](#upgrade-minor-version)
  * [Upgrade Major Version](#upgrade-major-version)
  * [Clean Install](#clean-install)
* [Build](#build)
  * [Build and Stage](#build-and-stage)
  * [Debug](#debug)
* [Configuration](#configuration)
  * [Docker](#docker)
  * [Packages](#packges)
  * [/etc/apache2/httpd.conf](#etc-apache2-httpd-conf)
    * [Rewrite Module](#rewrite-module)
    * [PHP7 Module](#php7-module)
    * [MPM Prefork Module](#mpm-prefork-module)
  * [/etc/php7/php.ini](#etc-php7-php-ini)

## Deployment <a name="deployment"/></a>
Choose a location to store your phpbb deployment. I'll be using ***/srv*** for this example and
running on ***cyberlinux*** so some things are specific to that distro.

### Run Current Deployment <a name="run-current-deployment"/></a>
Run docker container manually to test:
```bash
docker run --name phpbb -v /srv/http:/www/http -p 80:80 phr0ze/alpine-phpbb
```

Configure docker log mangment to avoid filling your disk:
```bash
sudo tee -a /etc/docker/daemon.json <<EOL
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOL
```

Create the systemd unit
```bash
sudo tee -a /usr/lib/systemd/system/phpbb.service <<EOL
[Unit]
Description=phpBB
After=docker.service
Requires=docker.service

[Service]
Restart=always
RestartSec=30s
TimeoutStartSec=0
TimeoutStopSec=0
ExecStart=/usr/bin/docker run --name phpbb -v /srv/http:/www/http -p 80:80 phr0ze/alpine-phpbb
ExecStop=/usr/bin/docker kill phpbb
ExecStopPost=/usr/bin/docker rm -f phpbb

[Install]
WantedBy=multi-user.target
EOL
```

### Backup Current Deploymet <a name="backup-current-deployment"/></a>
```bash
# Create a tarball of current deployment
cd /srv
sudo tar cvzf http-2018.10.2.tar.gz http

# Backup tarball to a backup location
scp http-2018.10.2.tar.gz 192.168.1.3:~/Downloads/Backup/phpBB
```

### Restore Current Deploymet <a name="restore-current-deployment"/></a>
```bash
# Copy the tarball from backup to target location
cd /srv
sudo rm -rf http
sudo cp ~/Downloads/Backup/http-2018.10.2.tar.gz .
sudo tar xvzf http-2018.10.2.tar.gz

# Ensure database location is called out in 'config.php'
# Note b/c the container location is /www not /srv as on host you need this
# $dbhost = '/www/http/phpBB.db'
```

### Upgrade Minor Version e.g. 3.2.1 to 3.2.3 <a name="upgrade-minor-version"/></a>
1. Prepare Current Deployment  
 a. [Backup Current Deployment](#backup-current-deployment)  
 b. Navigate to the ***ACP >Board Settings*** and make sure ***prosilver*** as the theme  
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
  sudo rm -rf phpBB3/{config.php,images,files,store} phpBB3/ext/phpbb/viglink
  sudo chown -R http: phpBB3

  # Remove .htaccess if it only has db changes
  diff http/.htaccess phpBB3/.htaccess
  sudo rm phpBB3/.htaccess
  ```
3. Deploy upgraded new bits
  ```bash
  # Copy phpBB3 to current deployment
  sudo cp -a phpBB3/* http

  # Note http/config.php must be in terms of the container path
  ```
4. Ensure datbase is in ***.htaccess***  
  a. Edit ***/srv/http/.htaccess***  
  b. Ensure db is listed under the appropriate versions  
5. Update the datbase
  ```bash
  docker run --rm -it --name phpbb -v /srv/http:/www/http phr0ze/alpine-phpbb bash
  cd http
  su -s /bin/bash -c 'php bin/phpbbcli.php db:migrate --safe-mode' http

  # Now exit the previous container and start a new one
  docker run --rm --name phpbb -v /srv/http:/www/http -p 80:80 phr0ze/alpine-phpbb
  ```
6. Update the rest of the site  
  a. Navigate to ***http://example.com/install***  
  b. Click the ***UPDATE*** tab  
  c. Click the ***Update*** at the bottom  
  d. Click ***Submit*** with ***Update database only*** selected  
  e. One complete terminate the docker container
7. Clean up
  ```bash
  # Delete install folder
  sudo rm -rf http/install

  # Delete phpBB3 upgrade leftovers
  sudo rm -rf phpBB3 phpBB-3.2.3.zip
  ```
8. Start the service
  ```bash
  sudo systenctl start phpbb
  ```

### Upgrade Major Version e.g. 3.1 to 3.2 <a name="upgrade-major-version"/></a>
1. [Backup Current Deployment](#backup-current-deployment)
2. Prepare latest phpBB for deployment
  ```bash
  # Navigate to https://www.phpbb.com/downloads/ and determine latest version
  sudo wget https://www.phpbb.com/files/release/phpBB-3.2.3.zip

  # Extract phpbb zip and rename
  sudo unzip phpBB-3.2.3.zip

  # Remove place holders and set ownership
  sudo rm -rf phpBB3/{config.php,images,files,store} phpBB3/ext/phpbb/viglink
  sudo chown -R http: phpBB3

  # Remove .htaccess if it only has db changes
  diff http/.htaccess phpBB3/.htaccess
  sudo rm phpBB3/.htaccess
  ```
3. Deploy upgraded new bits
  ```bash
  # Copy current deployment content to new phpBB deployment
  sudo cp -a http/{config.php,.htaccess,phpBB.db,images,files,store} phpBB

  # Stage phpBB as new deployment
  sudo mv http http_old
  sudo mv phpBB http
  ```
4. Ensure database is in ***.htaccess*** and ***config.php*** has correct db path  
  a. Edit ***/srv/http/.htaccess*** as needed  
  b. Edit ***/srv/http/config.php*** as needed  
5. Update the datbase
  ```bash
  docker run --rm -it --name phpbb -v /srv/http:/www/http phr0ze/alpine-phpbb bash
  cd http
  su -s /bin/bash -c 'php bin/phpbbcli.php db:migrate --safe-mode' http

  # Now exit the previous container and start a new one
  docker run --rm --name phpbb -v /srv/http:/www/http -p 80:80 phr0ze/alpine-phpbb
  ```
6. Update the rest of the site  
  a. Navigate to ***http://example.com/install***  
  b. Click the ***UPDATE*** tab  
  c. Click the ***Update*** at the bottom  
  d. Click ***Submit*** with ***Update database only*** selected  
7. Delete install folder  
  ```bash
  sudo rm -rf /srv/http/install
  ```

### Clean Install <a name="clean-install"/></a>
1. Prepare latest phpBB for deployment
  ```bash
  # Prepare location for installed bits
  cd /srv
  sudo rm -rf http

  # Navigate to https://www.phpbb.com/downloads/ and determine latest version
  sudo wget https://www.phpbb.com/files/release/phpBB-3.2.3.zip

  # Extract phpbb zip, set ownership and rename
  sudo unzip phpBB-3.2.3.zip
  sudo chown -R http: phpBB3
  sudo mv phpBB3 http

  # Remove cruft
  sudo rm -rf http/ext/phpbb/viglink

  # Create database file
  sudo -u http touch http/phpBB.db
  ```
2. Launch phpBB for configuration
  ```bash
  docker run --rm --name phpbb -v /srv/http:/www/http -p 80:80 phr0ze/alpine-phpbb
  ```
3. Install phpBB  
  a. Browse to ***http://example.com/install***  
  b. Click the ***INSTALL*** tab  
  c. Click ***Install*** button at bottom  
  d. Enter admin creds  
4. Configure database  
  a. Set ***Database type*** to ***SQLite 3***  
  b. Set ***Database server hostname or DSN*** to ***/www/http/phpBB.db***  
  c. Leave ***Database server port***, ***Database username***, and ***Database password*** blank  
  e. Set ***Database name*** to ***phpBB***  
  f. Leave ***Prefix for tables in database*** as ***phpbb_***  
  g. Click ***Submit***  
5. Email configuration  
  a. Set ***Enable board-wide emails*** to ***Disable***  
  b. Click ***Submit***  
6. Bulletin board configuration  
  a. Set ***Default language*** to ***British English***  
  b. Set ***Title of the board*** to ***Example Forum***  
  d. Click ***Submit***  
7. Final configuration  
  a. Click ***Take me to the ACP***  
  b. Now delete install directory: `sudo rm -rf /srv/http/install`  


## Build <a name="build"/></a>
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

## Configuration <a name="configuration"/></a>

### Packages <a name="packages"/></a>

#### Arch Linux
```bash
sudo pacman -S apache php php-apache php-sqlite php-gd
```

#### Alpine Linux
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

#### Rewrite Module <a name="rewrite-module"/></a>


#### PHP7 Module <a name="php7-module"/></a>
The ***mod_php7*** module is loaded by default, no ***httpd.conf*** setting is required

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
