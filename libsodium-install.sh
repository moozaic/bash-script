#!/bin/bash
#
# Install LibSodium and LibSodium-PHP


LIBSODIUM_SRC="libsodium-LATEST.tar.gz"

BLU='\033[1;34m'
RED='\033[1;31m'
GRN='\033[1;32m'
NC='\033[0m'
NB_PROC=$(grep -c ^processor /proc/cpuinfo)

INFO=${BLU}LibSodium${NC}

echo -ne "$INFO: Downloading... "
wget -q -O ${LIBSODIUM_SRC} https://download.libsodium.org/libsodium/releases/LATEST.tar.gz
echo "Done"

LIBSODIUM_DIR=`tar tzf ${LIBSODIUM_SRC} | head -1 | cut -f1 -d"/"`
echo -ne "$INFO: Extracting... "
tar zxf libsodium-LATEST.tar.gz
echo "Done"

cd ${LIBSODIUM_DIR}
echo -ne "$INFO: Configuring... "
./configure > libsodium-config.log 2>&1
echo "Done"

echo -ne "$INFO: Compiling... "
make -j $NB_PROC > libsodium.log 2>&1
echo "Done"

make check

echo -ne "$INFO: Installing... "
sudo make install > libsodium.log 2>&1
echo "Done"

echo -e "$INFO: Install PHP extension... "
pecl install libsodium

