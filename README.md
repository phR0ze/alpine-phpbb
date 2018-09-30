# alpine-php
Docker container for a php deployment

## Overview
Built off of Alpine Linux which is the defacto standard for production containers.

## Configuration
* httpd.conf

### MPM Prefork
Using the ***mpm_prefork_module***

```bash
ServerTokens Prod
ServerRoot /www
User apache
Group apache
ServerSignature Off
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
