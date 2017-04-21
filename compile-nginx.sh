#!/usr/bin/env bash
#
#################################################################
# Compile and Install Nginx, LibreSSL (static), PCRE, Brotli
# Optional nginx modules: Cache Purge, Headers More, Push Stream
# and NAXSI.
#
# Rev: 21.04.17
# Tested on Debian 8
#################################################################


########## START EDIT ##########

# BASE DIR
baseDir=$HOME

# BUILD DIR
buildDir=build

# NGINX EXECUTABLE
nginx=/usr/sbin/nginx

########## MODULES ############
#  1 : enabled, 0 : disabled  #
###############################

# NAXSI (default: disabled)
MOD_NAXSI=0

# CACHE PURGE (default: enabled)
MOD_CACHE_PURGE=1

# PUSH STREAM (default: enabled)
MOD_PUSH_STREAM=1

# HEADERS MORE (default: enabled)
MOD_HEADERS_MORE=1

####### MODULE OPTION #######
#  1 : dynamic, 0 : static  #
#############################

# MOD_NAXSI (default: dynamic)
DYNAMIC_NAXSI=1

# MOD_CACHE_PURGE (default: static)
DYNAMIC_CACHE_PURGE=0

# MOD_PUSH_STREAM (default: static)
DYNAMIC_PUSH_STREAM=0

# MOD_HEADERS_MORE (default: static)
DYNAMIC_HEADERS_MORE=0

########## STOP EDIT ##########

RED='\033[1;91m'
GRN='\033[1;32m'
BLU='\033[1;34m'
#NC='\033[0m'
NC='\e[0m'

export MYDIR=$baseDir/$buildDir

moozlog=$MYDIR/mooz_compile.log
nginx_version=$baseDir/mooz_nginx_version
libressl_version=$baseDir/mooz_libressl_version
DL_NGINX=0
DL_LIBRESSL=0
NB_PROC=$(grep -c ^processor /proc/cpuinfo)

# GET CURRENT NGINX VERSION
if [ ! -f $nginx_version ]; then
    nv=$($nginx -V 2>&1 | sed -n 's/.*nginx version: nginx\///p')
    touch $nginx_version
    echo $nv > $nginx_version
fi

# GET CURRENT LIBRESSL VERSION
if [ ! -f $libressl_version ]; then
    lv=$($nginx -V 2>&1 | sed -n 's/.*built with LibreSSL //p')
    touch $libressl_version
    echo $lv > $libressl_version
fi

currentNginxVer=$(cat $nginx_version)
currentLibresslVer=$(cat $libressl_version)

# DEFAULT NGINX VERSION
if [[ -z "${currentNginxVer// }" ]]; then
    currentNginxVer="1.0.0"
fi

# DEFAULT LIBRESSL VERSION
if [[ -z "${currentLibresslVer// }" ]]; then
    currentLibresslVer="1.0.0"
fi

# GET THE LATEST NGINX VERSION
latestNginxVer=$(curl -s 'http://nginx.org/en/download.html' | 
   sed 's/</\'$'\n''</g' | sed -n '/>Stable version$/,$ p' |
   egrep -m1 -o '/download/nginx-.+\.tar\.gz' |
   grep -oP '/download/nginx-\K[0-9]+\.[0-9]+\.[0-9]+' | 
   sort -t. -rn -k1,1 -k2,2 -k3,3 | head -1)

# GET THE LATEST LIBRESSL VERSION
latestLibresslVer=$(curl -s 'http://www.libressl.org/' |
   sed -n 's/^.*\(The latest stable release is \)\([0-9]*\.[0-9]*\.[0-9]*\).*$/\2/p')

# GET THE LATEST PCRE 8.x
latestPCRE=$(curl -s 'http://www.pcre.org/' |
    sed -n 's/^.*\(1997, is at version \)\([0-9]*\.[0-9]*\).*$/\2/p')

vercomp () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

# COMPARE FUNCTION
testvercomp () {
    vercomp $1 $2
    case $? in
        0) op='=';;
        1) op='>';;
        2) op='<';;
    esac
    if [[ $op != $3 ]]
    then
        return 1
    else
        return 0
    fi
}

# EXTRACT FUNCTION
extract_archive() {
  cd $MYDIR
  echo -e "Extracting."
  tar xzf "$1"

}

# DOWNLOAD FUNCTION
download_file() {
  cd $MYDIR
  echo -ne "  - Downloading ${GRN}$1${NC}... "
  if [ ! -f "$FILE" ]; then
    wget -P ./ "$2""$1" >> $moozlog 2>&1
    extract_archive "$1"
  else
    echo -e "Skipping."
  fi
}

# GIT CLONE FUNCTION
git_clone() {
  cd $MYDIR
  echo -e "  - Git clone ${GRN}$1${NC}..."
  if [ ! -d "$1" ]; then
    git clone "$2" >> $moozlog 2>&1
  else
    echo -e "Skipping."
  fi
}

echo ""

# Compare Nginx version
testvercomp $latestNginxVer $currentNginxVer '>'
if [ $? -eq 0 ]; then
    DL_NGINX=1
    export NGINX_VERSION=$latestNginxVer
    echo -e "[ ${RED}UPGRADE${NC} ] NGINX: $currentNginxVer to version ${GRN}$latestNginxVer${NC}"
else
    export NGINX_VERSION=$currentNginxVer
fi

# Compare LibreSSL version
testvercomp $latestLibresslVer $currentLibresslVer '>'
if [ $? -eq 0 ]; then
    DL_LIBRESSL=1
    export VERSION_LIBRESSL=libressl-$latestLibresslVer
    echo -e "[ ${RED}UPGRADE${NC} ] LIBRESSL: $currentLibresslVer to version ${GRN}$latestLibresslVer${NC}"
else
    export VERSION_LIBRESSL=libressl-$currentLibresslVer
fi

# Nginx and LibreSSL are up-to-date
if [ "$DL_NGINX" -eq 0 ] && [ "$DL_LIBRESSL" -eq 0 ]; then
    echo -e "[ ${GRN}SKIP${NC} ] Nginx $currentNginxVer and LibreSSL $currentLibresslVer are up-to-date...\n"
    exit 0
fi

echo -e "\n = = = = =\n"

export VERSION_NGINX=nginx-$NGINX_VERSION
export VERSION_PCRE=pcre-$latestPCRE
export SOURCE_LIBRESSL=http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/
export SOURCE_PCRE=ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/
export SOURCE_NGINX=http://nginx.org/download/
export LUAJIT_LIB=/usr/local/lib
export LUAJIT_INC=/usr/local/include/luajit-2.1

echo -e "[ ${GRN}PREPARING${NC} ]"

if [ -d "$MYDIR" ]; then
  echo -e "  - Removing old ${BLU}$MYDIR${NC} directory."
  cd $baseDir
  rm -rf $MYDIR
fi

echo -e "  - Create temporary ${BLU}$MYDIR${NC} directory."
mkdir -p $MYDIR
cd $MYDIR
touch $moozlog

echo -e "\n[ ${GRN}GET SOURCES${NC} ]"
# PCRE. Download. Extract
download_file $VERSION_PCRE.tar.gz $SOURCE_PCRE

# LIBRESSL. Download. Extract
download_file $VERSION_LIBRESSL.tar.gz $SOURCE_LIBRESSL

# NGINX. Download. Extract
download_file $VERSION_NGINX.tar.gz $SOURCE_NGINX

# BROTLI
git_clone brotli https://github.com/google/brotli.git

# BROTLI WRAPPER
git_clone libbrotli https://github.com/bagder/libbrotli

# BROTLI NGINX MODULE
git_clone ngx_brotli https://github.com/google/ngx_brotli

# ADD SUB-MODULE
echo -e "  - Git clone ${GRN}ngx_brotli${NC} sub module..."
cd $MYDIR/ngx_brotli && git submodule update --init --recursive >> $moozlog 2>&1

# NAXSI
if [ "$MOD_NAXSI" -eq 1 ]; then
  #echo -ne "${GRN}Nginx Module: NAXSI...${NC} "
  if [ "$DYNAMIC_NAXSI" -eq 1 ]; then
    export MODULE_NAXSI="--add-dynamic-module=$MYDIR/naxsi/naxsi_src "
  else
    export MODULE_NAXSI="--add-module=$MYDIR/naxsi/naxsi_src "
  fi
  git_clone ngx_naxsi https://github.com/nbs-system/naxsi.git
else
  export MODULE_NAXSI=""
fi

# CACHE PURGE
if [ "$MOD_CACHE_PURGE" -eq 1 ]; then
  if [ "$DYNAMIC_CACHE_PURGE" -eq 1 ]; then
    export MODULE_CACHE_PURGE="--add-dynamic-module=$MYDIR/ngx_cache_purge "
  else
    export MODULE_CACHE_PURGE="--add-module=$MYDIR/ngx_cache_purge "
  fi
  git_clone ngx_cache_purge https://github.com/FRiCKLE/ngx_cache_purge
else
  export MODULE_CACHE_PURGE=""
fi

# PUSH STREAM
if [ "$MOD_PUSH_STREAM" -eq 1 ]; then
  if [ "$DYNAMIC_PUSH_STREAM" -eq 1 ]; then
    export MODULE_PUSH_STREAM="--add-dynamic-module=$MYDIR/nginx-push-stream-module "
  else
    export MODULE_PUSH_STREAM="--add-module=$MYDIR/nginx-push-stream-module "
  fi
  git_clone nginx-push-stream-module https://github.com/wandenberg/nginx-push-stream-module
else
  export MODULE_PUSH_STREAM=""
fi

# HEADERS MORE
if [ "$MOD_HEADERS_MORE" -eq 1 ]; then
  if [ "$DYNAMIC_HEADERS_MORE" -eq 1 ]; then
    export MODULE_HEADERS="--add-dynamic-module=$MYDIR/headers-more-nginx-module "
  else
    export MODULE_HEADERS="--add-module=$MYDIR/headers-more-nginx-module "
  fi
  git_clone headers-more-nginx-module https://github.com/openresty/headers-more-nginx-module
else
  export MODULE_HEADERS=""
fi

echo -e "\n[ ${GRN}COMPILE SOURCES${NC} ]"

# COMPILE BROTLI
cd $MYDIR/brotli
echo -e "  - Compiling ${GRN}brotli${NC}..."
sudo python setup.py install >> $moozlog 2>&1
sudo make -j $NB_PROC >> $moozlog 2>&1

# COMPILE BROTLI WRAPPER
cd $MYDIR/libbrotli
echo -e "  - Compiling ${GRN}libbrotli${NC}..."
./autogen.sh >> $moozlog 2>&1
./configure >> $moozlog 2>&1
make -j $NB_PROC >> $moozlog 2>&1
sudo make install >> $moozlog 2>&1

# COMPILE STATIC LIBRESSL
export STATICLIBSSL=$MYDIR/$VERSION_LIBRESSL
cd $STATICLIBSSL
echo -ne "  - Configuring ${GRN}LibreSSL${NC}... "
./configure LDFLAGS=-lrt --prefix=${STATICLIBSSL}/.openssl/ >> $moozlog 2>&1
echo -e "Compiling..."
make install-strip -j $NB_PROC >> $moozlog 2>&1

# CONFIGURING NGINX
echo -ne "  - Configuring ${GRN}Nginx${NC}... "
cd $MYDIR/$VERSION_NGINX
./configure \
    $MODULE_NAXSI \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --user=nginx \
    --group=nginx \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-http_slice_module \
    --with-file-aio \
    --with-http_v2_module \
    --with-ipv6 \
    --without-http_autoindex_module \
    --without-http_ssi_module \
    --with-ld-opt="-lrt -Wl,-rpath,/usr/local/lib" \
    --with-pcre=$MYDIR/$VERSION_PCRE \
    --with-openssl=$STATICLIBSSL \
    --add-module=$MYDIR/ngx_brotli \
    $MODULE_CACHE_PURGE \
    $MODULE_PUSH_STREAM \
    $MODULE_HEADERS >> $moozlog 2>&1

#echo "export BROTLI static module"
export NGX_BROTLI_STATIC_MODULE_ONLY=1

#echo "touch LibreSSL"
touch $STATICLIBSSL/.openssl/include/openssl/ssl.h

echo -e "Compiling..."
cd $MYDIR/$VERSION_NGINX
make -j $NB_PROC >> $moozlog 2<&1

# CREATE PACKAGE AND INSTALL
echo -ne "\n[ ${GRN}PACKAGING/INSTALL${NC} ] "
sudo checkinstall --pkgname="nginx-libressl" --pkgversion="$NGINX_VERSION" --provides="nginx" --requires="libc6, libpcre3, zlib1g" --strip=yes --stripso=yes --backup=yes -y --install=yes >> $moozlog 2>&1

sudo chown -R ${USER:=$(/usr/bin/id -run)}:$USER $MYDIR

echo "$latestNginxVer" > $nginx_version
echo "$latestLibresslVer" > $libressl_version

# DONE
echo -e "Done!"

exit 0
