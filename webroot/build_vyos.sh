#!/bin/sh -e

ENV=$HOME/build_vyos.env

if [ -r "$ENV" ]
then
  . "$ENV"
else
  exit 1
fi

# Fetch source tree if we don't already have it
SRC_DIR=${HOME}/$(basename $VYOS_SRC)
if [ ! -r $SRC_DIR ]
then
  git clone -b current --single-branch $VYOS_SRC $SRC_DIR
fi

CONTAINER="vyos/vyos-build"
TAG=${CONTAINER_TAG:-current}
if [ \"x$BUILD_CONTAINER\" = \"xtrue\" ]
then
  (cd $SRC_DIR; docker build -t $CONTAINER docker)
else
  docker pull $CONTAINER:$TAG
fi

docker run --rm --privileged -v $SRC_DIR:/vyos -w /vyos $CONTAINER:$TAG ./configure --custom-package "$CUSTOM_PKGS" --architecture $ARCH --build-by $BUILD_BY --build-type release --version $VYOS_VER
docker run --rm --privileged -v $SRC_DIR:/vyos -w /vyos $CONTAINER:$TAG sudo make iso
