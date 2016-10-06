#!/bin/bash
#
# BROTLI/GZIP: compress CSS and JS files
# in directory (recursive) for use with Webserver
#
# Usage: ./bro-compress.sh [ -c ] [ -d ] directory
# c : to compress files
# d : to remove compressed files
#
# eg.: bro-compress.sh -c /var/www/mywebsite

###################
#  CONFIGURATION  #
###################

# Compress using brotli? (boolean)
USE_BRO=1

# Compress using gzip? (boolean)
USE_GZP=1

# Brotli executable (path)
BRO=/opt/brotli/bin/bro

# Nginx/Apache/Webserver user
WEBUSER=www-data
WEBGROUP=www-data

###################
#     ROUTINE     #
###################

NAME="bro-compress.sh"
BLU='\033[1;34m'
RED='\033[1;31m'
GRN='\033[1;32m'
NC='\033[0m'

# compress using brotli and gzip
bro_action() {
  echo -e "Compressing ${GRN}$1${NC}"
  if [ "$USE_BRO" -gt 0 ]; then
    $BRO --input $1 --force --output $1.br;
    chmod 0644 $1.br;
  fi

  if [ "$USE_GZP" -gt 0 ]; then
    gzip -9 $1 -c > $1.gz;
    chmod 0644 $1.gz;
  fi
  chown $WEBUSER:$WEBGROUP $1.br $1.gz;
}

# find CSS/JS files in directory and sub-directory
do_compress() {
  echo -e "\nProcessing CSS : ${BLU}$1${NC}"
  for x in `find $1 -type f -name '*.css'`; do bro_action ${x}; done
  echo -e "Done.\n"

  echo -e "Processing JS : ${BLU}$1${NC}"
  for x in `find $1 -type f -name '*.js'`; do bro_action ${x}; done
  echo -e "Done.\n"
}

# delete compressed files
remove_compress() {
  echo -e "\nRemoving compressed files in ${BLU}$1${NC}"
  for x in `find $1 -type f -name '*.gz' -o -name '*.br'`; do
    rm -f ${x}
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

if [ $USE_BRO -eq 0 ] && [ $USE_GZP -eq 0 ]; then
  echo "Edit configuration in $NAME"
  exit 3
fi

if [ $# -ne 2 ]; then
  print_usage
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
