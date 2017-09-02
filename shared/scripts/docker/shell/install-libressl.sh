#!/bin/sh
set -x
set -e

clear
echo

export COMMON_SCRIPT=$(find /app/shared -name "common.sh")
export COMMON_SCRIPT_DIR=$(dirname ${COMMON_SCRIPT})
if [ -f ${COMMON_SCRIPT} ]; then
	source ${COMMON_SCRIPT}
fi

# Set temp environment vars
export LIBRESSL_CPP_DEBUG=0
export LIBRESSL_VCS_REPO=https://github.com/libressl-portable/portable
export LIBRESSL_VCS_CLONE_BRANCH=master
export LIBRESSL_VCS_CLONE_DEPTH=1
export LIBRESSL_VCS_CLONE_PATH=/tmp/$(basename $LIBRESSL_VCS_REPO)
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

# Install build deps
apk --no-cache --no-progress --virtual .$(basename $LIBRESSL_VCS_REPO)-build-deps add g++ gcc musl-dev make autoconf automake

if [ -d ${LIBRESSL_VCS_CLONE_PATH} ];then
	rm -fR ${LIBRESSL_VCS_CLONE_PATH}
fi

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

# Compile & Install libgit2 (v0.23)
git clone -b ${LIBRESSL_VCS_CLONE_BRANCH} --recursive --depth ${LIBRESSL_VCS_CLONE_DEPTH} -- ${LIBRESSL_VCS_REPO} ${LIBRESSL_VCS_CLONE_PATH}

cd ${LIBRESSL_VCS_CLONE_PATH}

./autogen.sh
./configure   # see ./configure --help for configuration options
make check    # runs builtin unit tests
make install  # set DESTDIR= to install to an alternate location

# Remove build deps
# apk --no-cache --no-progress del .$(basename $LIBRESSL_VCS_REPO)-build-deps

# Cleanup
rm -r ${LIBRESSL_VCS_CLONE_PATH}