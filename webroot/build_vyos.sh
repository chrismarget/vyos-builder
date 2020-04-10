#!/bin/sh
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

# Fetch or build the vyos-build container
CONTAINER="vyos/vyos-build"
if [ "$BUILD_CONTAINER" = "true" ]
then
  TAG=latest
  (cd $SRC_DIR; docker build -t $CONTAINER docker)
else
  TAG=${CONTAINER_TAG:-current}
  docker pull $CONTAINER:$TAG
fi

OVERLAY="-v $SRC_DIR:/vyos"
CMD="./configure --custom-package "$CUSTOM_PKGS" --architecture $ARCH --build-by $BUILD_BY --build-type release --version $VYOS_VER"
docker run --rm --privileged $OVERLAY -w /vyos $CONTAINER:$TAG sh -c "$CMD"

CMD="sudo make $VYOS_TARGET"
case ${VYOS_TARGET} in
  "vmware")
    CMD="sudo ln -s /bin/true /bin/ovftool; $CMD"
    ;;
  "iso")
    ;;
esac

docker run --rm --privileged $OVERLAY -w /vyos $CONTAINER:$TAG sh -c "$CMD"

if [ -z "$TIMESTAMP" ]
then
  BUILD_DIR=${HOME}/$BUILD_DIR
else
  BUILD_DIR=${HOME}/$BUILD_DIR-$TIMESTAMP
fi
mkdir -p $BUILD_DIR

echo "BUILD_DIR=$BUILD_DIR" >> /tmp/var
echo "VYOS_TARGET=$VYOS_TARGET" >> /tmp/var
echo "SRC_DIR=$SRC_DIR" >> /tmp/var
echo "VYOS_VER=$VYOS_VER" >> /tmp/var

case ${VYOS_TARGET} in
  "vmware")
    FILES="vyos_vmware_image.ovf vyos_vmware_image.vmdk vyos_vmware_image.mf"
    echo "If there's an error about private keys directly above this, then the build didn't necessarily fail."
    echo "The build should have produced the following files: $FILES"
    echo "Try to grab them..."
    (cd ${SRC_DIR}/build/; ls -l $FILES)
    tar cvf ${BUILD_DIR}/vyos_vmware_image.ova -C ${SRC_DIR}/build $FILES
    ;;
  "iso")
    ln -s ${SRC_DIR}/build/vyos-${VYOS_VER}-${ARCH}.iso $BUILD_DIR
    ;;
esac
