#!/bin/sh
set -x
set -e

clear
echo

DIR=$(dirname "$0")
echo "$DIR"
. ${DIR}/common.sh

## #################################################################
## global env variables
## #################################################################

# Set temp environment vars
export PROJECT_VCS_URI=${PROJECT_VCS_URI:-"github.com/TigorC/aiounfurl"}
export PROJECT_VCS_BRANCH=${PROJECT_VCS_BRANCH:-"master"}
export PROJECT_VCS_CLONE_DEPTH=${PROJECT_VCS_CLONE_DEPTH:-"1"}
export PROJECT_VCS_CLONE_PATH=${PROJECT_VCS_CLONE_PATH:-"/app/$(basename $PROJECT_VCS_URI)"}

ensure_dir ${MS_BOND_VCS_CLONE_PATH}

export SRC_BUILD_DEPS="pip3"
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

# Clone, Compile & Install
git clone -b ${PROJECT_VCS_BRANCH} --recursive \
		--depth ${PROJECT_VCS_CLONE_DEPTH} -- https://${PROJECT_VCS_URI} ${PROJECT_VCS_CLONE_PATH}

pip3 install --no-cache --no-cache-dir -e .

ls -l 