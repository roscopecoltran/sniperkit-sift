#!/bin/sh
set -x
set -e

clear
echo

export CONTAINER_MODE=${CONTAINER_MODE-:"dev"}
export CONTAINER_NB_CORES=${CONTAINER_NB_CORES-$(getconf _NPROCESSORS_CONF)}

export CONTAINER_CMAKE_BUILD_TYPE=${CONTAINER_CMAKE_BUILD_TYPE:-"Release"}


function ensure_dir {
	clear
	echo -e " "
	echo -e " **** ensure_dir $1 *** "
	if [ -d ${1} ]; then
		tree ${1}
		rm -fR ${1}
	fi
	mkdir -p ${1}
	echo -e " "
}

function check_generated_output {
	pwd
	ls -l 
}

export GOLANG_TOOLS_GITHUB_URIS=${GOLANG_TOOLS_GITHUB_URIS:-"Masterminds/glide mitchellh/gox dahernan/godockerize"}
function ensure_golang_tools {
	for godep in ${GOLANG_TOOLS_GITHUB_URIS}; do
		GOLANG_BASENAME_DEP=$(basename $godep)
	    GOLANG_DEP_EXECUTABLE=$(which $GOLANG_BASENAME_DEP) 
	    if [ ! -f ${GOLANG_DEP_EXECUTABLE} ]; then
	    	go get -v ${godep}
	    fi
	done  
}

export DOCKER_CONTAINER_HOST=$(ifconfig | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v 127.0.0.1 | awk '{ print $2 }' | cut -f2 -d: | head -n1)
ensure_golang_tools
