#!/bin/sh
set -x
set -e

clear
echo

export COMMON_SCRIPT=$(find /app/shared -name "common.sh")
if [ -f ${COMMON_SCRIPT} ]; then
	source ${COMMON_SCRIPT}
fi
## #################################################################
## global env variables
## #################################################################

export DOCKER_BUILD_WORKSPACE=${DOCKER_BUILD_WORKSPACE:-"/tmp/berkeley-db"}
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

## #################################################################
## apk
## #################################################################

# Install build deps
apk --no-cache --no-progress --update \
	--repository http://dl-3.alpinelinux.org/alpine/edge/testing/ \
	--allow-untrusted \
	--virtual .$(basename $DLIB_VCS_REPO)-build-deps add musl-dev make g++ gcc openblas openblas-dev boost-dev boost

export SRC_BUILD_DEPS=""
for dep in ${SRC_BUILD_DEPS}; do
	if [ -z "$(which $dep)" ]; then
		if [ -f ${COMMON_SCRIPT_DIR}/install-${dep}.sh ]; then
			echo "found ${COMMON_SCRIPT_DIR}/install-${dep}.sh"
			chmod a+x ${COMMON_SCRIPT_DIR}/install-${dep}.sh
			${COMMON_SCRIPT_DIR}/install-${dep}.sh
		else
			echo "missing ${COMMON_SCRIPT_DIR}/install-${dep}.sh"
		fi
	fi
done

## #################################################################
## BerkleyDB - env variables
## #################################################################

# refs
#  - http://www.oracle.com/technetwork/database/database-technologies/berkeleydb/downloads/index.html

export BERKELEYDB_VERSION=${BERKELEYDB_VERSION:-"db-6.2.32.NC"}
export BERKELEYDB_SHASUM=${BERKELEYDB_SHASUM:-"d86cf1283c519d42dd112b4501ecb2db11ae765b37a1bdad8f8cb06b0ffc69b8"}
export BERKELEYDB_TARBALL_URL=${BERKELEYDB_TARBALL_PATH:-"http://download.oracle.com/berkeley-db/$BERKELEYDB_VERSION.tar.gz"}
export BERKELEYDB_TARBALL_PATH=${BERKELEYDB_TARBALL_PATH:-"$DOCKER_BUILD_WORKSPACE/$BERKELEYDB_VERSION"}
export BERKELEYDB_BUILD_PATH=${BERKELEYDB_BUILD_PATH:-"$DOCKER_BUILD_WORKSPACE/$BERKELEYDB_VERSION/build_unix"}
export BERKELEYDB_BUILD_ARGS=${BERKELEYDB_BUILD_ARGS:-"--enable-cxx --disable-shared --with-pic"}
export BERKELEYDB_PREFIX=${BERKELEYDB_PREFIX:-"/opt/$BERKELEYDB_VERSION"}

## #################################################################
## BerkleyDB - download and check
## #################################################################

ensure_dir ${DOCKER_BUILD_WORKSPACE}

wget -nc -O ${BERKELEYDB_TARBALL_PATH} ${BERKELEYDB_TARBALL_URL}
# BERKELEYDB_TARBALL_LOCAL_SHASUM=$(sha256sum ${BERKELEYDB_TARBALL_PATH})
# echo ${BERKELEYDB_TARBALL_LOCAL_SHASUM} | sha256sum -c
# echo "${BERKELEYDB_SHASUM} ${BERKELEYDB_TARBALL_PATH}" | sha256sum -c
# echo "d86cf1283c519d42dd112b4501ecb2db11ae765b37a1bdad8f8cb06b0ffc69b8" /tmp/build/db-6.2.32.NC.tar.gz

## #################################################################
## BerkleyDB - patch and compile source code
## #################################################################

tar -xzf ${BERKELEYDB_TARBALL_PATH} -C ${DOCKER_BUILD_WORKSPACE}
# sed s/__atomic_compare_exchange/__atomic_compare_exchange_db/g -i ${BERKELEYDB_TARBALL_PATH}/src/dbinc/atomic.h

ensure_dir ${BERKELEYDB_PREFIX}
ensure_dir ${BERKELEYDB_BUILD_PATH}

cd ${BERKELEYDB_BUILD_PATH}
pwd

../dist/configure ${BERKELEYDB_BUILD_ARGS} --prefix=${BERKELEYDB_PREFIX}

## #################################################################
## BerkleyDB - install generated libs and execs
## #################################################################

make install

## #################################################################
## BerkleyDB - remove build files from the container
## #################################################################

# ensure_dir ${DOCKER_BUILD_WORKSPACE}
# echo
