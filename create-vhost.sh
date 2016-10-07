#!/bin/bash
#
# CREATE NGINX VHOST
#

#################
# CONFIGURATION #
#################
SVR_DIR=/etc/nginx
BASE_DIR=/site-available
LINK_DIR=/site-enabled
WWW_DIR=/var/www
SKEL=./vhost-template/https.conf

###########
# ROUTINE #
###########
NAME="create-vhost.sh"
TARGET=$SVR_DIR$BASE_DIR
SYMLNK=$SVR_DIR$LINK_DIR

BLU='\033[1;34m'
RED='\033[1;31m'
GRN='\033[1;32m'
CYN='\033[1;96m'
NC='\033[0m'


print_usage() {
  echo -e "\nUsage: $NAME hostname domain\n"
}

if [ $# -ne 2 ]; then
  print_usage
  exit 3
fi

VHOST="$1"
DOMAIN="$2"

make_vhost() {
  if [ ! -f "$TARGET/$DOMAIN.conf" ]; then
    echo -e "\nCreate configuration file: ${GRN}$TARGET/$DOMAIN.conf${NC}"
    cat $SKEL > $TARGET/$DOMAIN.conf

    # Replace VHOST
    /bin/sed -i -e "s/VHOST/$VHOST/g" $TARGET/$DOMAIN.conf

    # Replace DOMAIN
    /bin/sed -i -e "s/DOMAIN/$DOMAIN/g" $TARGET/$DOMAIN.conf

    echo -e "Create symbolic link: ${CYN}$SYMLNK/$DOMAIN.conf${NC}"
    ln -s $TARGET/$DOMAIN.conf $SYMLNK/$DOMAIN.conf
  else
    echo -e "\n${RED}Skipped:${NC} ${GRN}$TARGET/$DOMAIN.conf${NC} already exists. "
  fi

  if [ ! -d "$WWW_DIR/$VHOST" ]; then
    echo -e "Create directory ${BLU}$WWW_DIR/$VHOST${NC} "
    mkdir $WWW_DIR/$VHOST

    echo -e "Create file ${GRN}index.html${NC} "
    echo "<code>$DOMAIN</code>" > $WWW_DIR/$VHOST/index.html
  else
    echo -e "${RED}Skipped:${NC} directory ${BLU}$WWW_DIR/$VHOST${NC} already exists.\n"
    exit 1
  fi

  #echo -e "Restarting Nginx... \n"
  service nginx restart
}

echo -e "\n[VHOST]"
echo -e "Host: ${GRN}$VHOST${NC}"
echo -e "Domain: ${GRN}$DOMAIN${NC}\n"

read -p "Make sure information above correct. Continue? [y/N] " yn

case $yn in
  [Yy]* ) make_vhost;;
  [Nn]* ) echo; exit 1;;
  * ) echo; exit 0;;
esac

exit 0
