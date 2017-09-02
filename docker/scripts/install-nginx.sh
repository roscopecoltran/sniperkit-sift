#!/bin/sh
set -x
set -e

clear
echo

if [ -f ./docker/scripts/common.sh ]; then
	source ./docker/scripts/common.sh
fi

# Set temp environment vars
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

export NGINX_VER=${NGINX_VCS_BRANCH}
export NGINX_VERSION=${NGINX_VCS_BRANCH}

export NGINX_BUILD_CONF=" \
    --prefix=/nginx \
    --sbin-path=/usr/local/sbin/nginx \
    --http-log-path=/shared/logs/nginx/logs/access.log \
    --error-log-path=/shared/logs/logs/error.log \
    --pid-path=/nginx/run/nginx.pid \
    --lock-path=/nginx/run/nginx.lock \
    --with-threads \
    --with-file-aio \
    --without-http_geo_module \
    --without-http_autoindex_module \
    --without-http_split_clients_module \
    --without-http_memcached_module \
    --without-http_empty_gif_module \
    --without-http_browser_module"

mkdir -p /shared/data/nginx/html
mkdir -p /shared/data/nginx/www
mkdir -p /shared/conf.d/nginx/
mkdir -p /shared/logs/nginx/

# Install build deps
apk --no-cache --no-progress --virtual .cmake-build-deps add g++ gcc musl-dev make autoconf automake

wget http://nginx.org/download/nginx-${NGINX_VER}.tar.gz -O /tmp/nginx-${NGINX_VER}.tar.gz
wget http://nginx.org/download/nginx-${NGINX_VER}.tar.gz.asc -O /tmp/nginx-${NGINX_VER}.tar.gz.asc
wget ${PHP_MIRROR}/get/php-${PHP_VER}.tar.gz/from/this/mirror -O /tmp/php-${PHP_VER}.tar.gz
wget ${PHP_MIRROR}/get/php-${PHP_VER}.tar.gz.asc/from/this/mirror -O /tmp/php-${PHP_VER}.tar.gz.asc
wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-${LIBICONV_VERSION}.tar.gz -O /tmp/libiconv-${LIBICONV_VERSION}.tar.gz
# mkdir -p /php/conf.d
mkdir -p /usr/src
tar xzf /tmp/nginx-${NGINX_VER}.tar.gz -C /usr/src
tar xzvf /tmp/php-${PHP_VER}.tar.gz -C /usr/src
tar xzf /tmp/libiconv-${LIBICONV_VERSION}.tar.gz -C /usr/src

### nginx installation
cd /usr/src/nginx-${NGINX_VER}
./configure --with-cc-opt="-O3 -fPIE -fstack-protector-strong" ${NGINX_CONF}
make -j${CONTAINER_NB_CORES}
make install

# Remove build deps
# apk --no-cache --no-progress del .cmake-build-deps

# Cleanup
rm -r ${NGINX_VCS_PATH}