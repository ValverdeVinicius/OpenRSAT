#!/bin/bash

# Usage:
# ./build.sh <VERSION:0.4.226> <ARCH:x64,arm64,arm32,x86> <ICON_PATH:./icon.png> [BIN_PATH]

USAGE="./build.sh <VERSION:0.4.226> <ARCH:x64,arm64,arm32,x86> <ICON_PATH:./icon.png> [BIN_PATH]"

set -ex

VERSION=$1
ARCH=$2
ICON_PATH=$3
BIN_PATH=${4:-}
URL="https://github.com/tranquilit/openrsat/releases/download/v"$VERSION
BUILDDIR=$PWD/builddir

if [ "$#" -lt 3 ]; then
  echo "Invalid number of arguments."
  echo "Usage:"
  echo "	$USAGE"
  exit
fi

echo "Verify architecture..."

if [ "$ARCH" = "x64" ]; then
  DEBARCH=amd64
elif [ "$ARCH" = "arm64" ]; then
  DEBARCH=arm64
elif [ "$ARCH" = "arm32" ]; then
  DEBARCH=armhf
elif [ "$ARCH" = "x86" ]; then
  DEBARCH=i386
else
  echo "Invalid architecture. Exit."
  exit
fi

echo "Architecture OK. "$ARCH" -> "$DEBARCH

echo "Remove remaining .deb files."
#rm -rf *.deb $BUILDDIR

echo "Create folder structure."
mkdir -p $BUILDDIR/DEBIAN
mkdir -p $BUILDDIR/{opt/openrsat/,usr/share/applications}
mkdir -p $BUILDDIR/usr/share/locale/{en,fr,pl,el}

echo "Copy control, postinst and postrm files."
cp ./control $BUILDDIR/DEBIAN
cp ./postinst $BUILDDIR/DEBIAN
cp ./postrm $BUILDDIR/DEBIAN

echo "Set permissions to postinst, postrm and control."
chmod 755 $BUILDDIR/DEBIAN/postinst
chmod 755 $BUILDDIR/DEBIAN/postrm
chmod 755 $BUILDDIR/DEBIAN/control

echo "Change version and architecture in control file."
sed -i -e "s/VERSION/$VERSION/" -e "s/^Architecture:.*/Architecture: $DEBARCH/" $BUILDDIR/DEBIAN/control

if [ -n "$BIN_PATH" ]; then
  echo "Copy local binary: $BIN_PATH"
  cp "$BIN_PATH" $BUILDDIR/opt/openrsat/OpenRSAT
else
  echo "Download binary for architecture $ARCH."
  wget -O $BUILDDIR/opt/openrsat/OpenRSAT $URL/OpenRSAT-linux-$ARCH
fi

echo "Copy icon."
[ -f "$ICON_PATH" ] || (echo "$ICON_PATH does not exists." && exit)
cp $ICON_PATH $BUILDDIR/opt/openrsat/OpenRSAT.png

echo "Copy desktop file."
[ -f "../OpenRSAT.desktop" ] || (echo "../OpenRSAT.desktop does not exists." && exit)
cp ../OpenRSAT.desktop $BUILDDIR/usr/share/applications/

echo "Copy locale files."
for l in en fr pl el
do
  [ -f "../../../languages/OpenRSAT.$l.po" ] || (echo "../../../languages/OpenRSAT.$l.po does not exists." && exit)
  cp ../../../languages/OpenRSAT.$l.po $BUILDDIR/usr/share/locale/$l/OpenRSAT.po
done

echo "Set permissions to binary, icon and desktop files."
chmod 755 $BUILDDIR/opt/openrsat/OpenRSAT
chmod 755 $BUILDDIR/opt/openrsat/OpenRSAT.png
chmod 755 $BUILDDIR/usr/share/applications/OpenRSAT.desktop
chmod 755 $BUILDDIR/usr/share/locale/en/OpenRSAT.po
chmod 755 $BUILDDIR/usr/share/locale/fr/OpenRSAT.po
chmod 755 $BUILDDIR/usr/share/locale/pl/OpenRSAT.po
chmod 755 $BUILDDIR/usr/share/locale/el/OpenRSAT.po

echo "Build deb file."
dpkg-deb --build $BUILDDIR OpenRSAT-${VERSION}-${DEBARCH}.deb

echo "Remove build folder."
rm -rf $BUILDDIR