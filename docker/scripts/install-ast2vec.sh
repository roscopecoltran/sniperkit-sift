#!/bin/sh
set -x
set -e

clear
echo

if [ -f ./docker/scripts/common.sh ]; then
	source ./docker/scripts/common.sh
fi

# Install build deps
apk add --no-cache --no-progress --virtual .ast2vec-build-deps gcc make python3-dev musl-dev musl g++ libxml2-dev libxslt-dev libffi-dev

pip3 install git+https://github.com/bblfsh/client-python
# pip3 install ast2vec

if [ -d /app/external/ast2vec ]; then
	rm -fR /app/external/ast2vec
fi

git clone --recursive --depth=1 https://github.com/src-d/ast2vec /app/external/ast2vec
cd /app/external/ast2vec

for p in /app/external/ast2vec/requirement*.txt; do pip3 install --no-cache --no-cache-dir -r $p; done
pip3 install --no-cache -e .

apk del --no-cache .ast2vec-build-deps