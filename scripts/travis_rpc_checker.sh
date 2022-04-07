#!/usr/bin/env bash
set -e

echo $TRAVIS_BRANCH
cd $HOME/gopath/src/github.com/harmony-one
cd $(go env GOPATH)/src/github.com/harmony-one/harmony-test
git checkout $TRAVIS_BRANCH || true
git branch --show-current
cd localnet
docker build -t harmonyone/localnet-test .


DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
#CACHE_DIR="docker_images"
#mkdir -p $CACHE_DIR
#echo "pulling cached docker img"
#docker load -i $CACHE_DIR/images.tar || true
#docker pull harmonyone/localnet-test
#echo "saving cached docker img"
#docker save -o $CACHE_DIR/images.tar harmonyone/localnet-test

#git clone https://github.com/harmony-one/harmony-test.git

docker run -v "$DIR/../:/go/src/github.com/harmony-one/harmony" harmonyone/localnet-test -n