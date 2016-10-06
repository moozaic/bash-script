#!/bin/bash
#
# Install Redis and PHPRedis


# DOWNLOAD/COMPILE DIRECTORY
BASE_DIR=/tmp

# REDIS FILE
REDIS_SRC="redis-STABLE.tar.gz"

# COLOR
BLU='\033[1;34m'
RED='\033[1;31m'
GRN='\033[1;32m'
NC='\033[0m'

# CPU
NB_PROC=$(grep -c ^processor /proc/cpuinfo)

# INFO
REDIS=${BLU}Redis${NC}
PHPREDIS=${BLU}PHPRedis${NC}


cd $BASE_DIR
echo -ne "$REDIS: Downloading... "
wget -q -O $REDIS_SRC http://download.redis.io/releases/redis-stable.tar.gz
echo "Done"

REDIS_DIR=`tar tzf $REDIS_SRC | head -1 | cut -f1 -d"/"`
echo -ne "$REDIS: Extracting... "
tar zxf $REDIS_SRC
echo "Done"

cd ${REDIS_DIR}
echo -ne "$REDIS: Configuring... "
./configure > redis-config.log 2>&1
echo "Done"

echo -ne "$REDIS: Compiling... "
make -j $NB_PROC > redis.log 2>&1
echo "Done"

make check

echo -ne "$REDIS: Installing... "
cd utils/
./install_server.sh
echo "Done"

echo -e "$PHPREDIS: Install PHP extension... "
cd $BASE_DIR
git clone https://github.com/phpredis/phpredis
cd phpredis/
phpize

echo -ne "$PHPREDIS: Configuring... "
./configure > phpredis.log 2>&1
echo "Done"

echo -ne "$PHPREDIS: Compiling... "
make -j $NB_PROC >> phpredis.log 2>&1
echo "Done"

echo -ne "$PHPREDIS: Installing... "
sudo make install >> phpredis.log 2>&1
echo "Done"
