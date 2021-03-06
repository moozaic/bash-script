#!/bin/bash
#
#####################################################
#                                                   #
# BROTLI/GZIP: compress CSS and JS files            #
# in directory (recursive) for use with Webserver   #
#                                                   #
# Usage: ./bro-compress.sh [ -c ] [ -d ] directory  #
# c : to compress files                             #
# d : to remove compressed files                    #
#                                                   #
# eg.: bro-compress.sh -c /var/www/mywebsite        #
#                                                   #
# FIX: file contain spaces                          #
#                                                   #
#####################################################


###################
#  CONFIGURATION  #
###################

# Compress using brotli? (boolean)
USE_BRO=0

# Compress using gzip? (boolean)
USE_GZP=0

# Brotli executable (path)
BRO=/opt/brotli/bin/bro

# Nginx/Apache/Webserver user
WEBUSER=www-data
WEBGROUP=www-data


#############
#  ROUTINE  #
#############

NAME="bro-compress.sh"
RED='\033[1;31m'
GRN='\033[1;32m'
NC='\033[0m'


bro_action() {
  echo -e "Compressing ${GRN}$1${NC}"
  if [ "$USE_BRO" -gt 0 ]; then
    $BRO --input "$1" --force --output "$1.br";
    chown $WEBUSER:$WEBGROUP "$1.br";
    chmod 0644 "$1.br";
  fi
  if [ "$USE_GZP" -gt 0 ]; then
    gzip -9 "$1" -c > "$1.gz";
    chown $WEBUSER:$WEBGROUP "$1.gz";
    chmod 0644 "$1.gz";
  fi
}

do_compress() {
  echo -e "\nProcessing CSS : ${RED}$1${NC}"
  find $1 -type f -iname "*.css" | while read -r x; do bro_action "${x}" ; done
  echo -e "Done.\n"

  echo -e "Processing JS : ${RED}$1${NC}"
  find $1 -type f -iname "*.js" | while read -r x; do bro_action "${x}" ; done
  echo -e "Done.\n"
}

remove_compress() {
  echo -e "\nRemoving compressed files in ${RED}$1${NC}"
  find $1 -type f -iname "*.gz" -o -iname "*.br" | while read -r x; do
    rm -f "${x}"
    echo -e "File ${GRN}${x}${NC}... ${RED}Deleted${NC}"
  done
}

bro_compress() {
  do_compress $1
}

bro_remove() {
  remove_compress $1
}

print_usage() {
  echo -e "\n Usage: $NAME [ -c ] [ -d ] directory\n Options: \n   c : to compress files\n   d : to remove compressed files\n"
}

if [ $# -ne 2 ]; then
  print_usage
  exit 3
fi

if [[ $USE_BRO -eq 0 ]] && [[ $USE_GZP -eq 0 ]]; then
  echo "Edit configuration in $NAME"
  exit 3
fi

case "$1" in
    -c)
      MYDIR="$2"
      bro_compress ${MYDIR}
      ;;
    -d)
      MYDIR="$2"
      bro_remove ${MYDIR}
      ;;
    *)
      print_usage
      exit 3
    ;;
esac

exit 0
