#!/bin/bash
#
# Create and mount /tmp directory with
# "noexec,nosuid,nodev" attribut.
#

TEST=1

TMPFILE="$1"
BLU='\033[1;34m'
RED='\033[1;31m'
GRN='\033[1;32m'
NC='\033[0m'
INFO=${GRN}${TMPFILE}${NC}

if [ -f "${TMPFILE}" ]; then
  echo -e "\nError: File ${RED}${TMPFILE}${NC} already exists\n"
  exit 3
fi

# backup /tmp directory
echo -ne "\nBackup ${BLU}/tmp${NC} directory... "
if [ "$TEST" -eq 0 ]; then
  cp -av /tmp /tmp.old
fi
echo "Done"

# create 1GB block size
echo -ne "${INFO}: creating file with size of 1GB... "
if [ "$TEST" -eq 0 ]; then
dd if=/dev/zero of=${TMPFILE} bs=1024 count=1000000 &> /dev/null
fi
echo "Done"

echo -ne "${INFO}: formating using EXT4... "
if [ "$TEST" -eq 0 ]; then
mkfs.ext4 -Fq ${TMPFILE}
fi
echo "Done"

echo -e "${INFO}: mounting ${BLU}/tmp${NC} directory... "
if [ "$TEST" -eq 0 ]; then
  mount -o loop,rw,noexec,nosuid,nodev ${TMPFILE} /tmp
fi

echo -e "${INFO}: chmod ${RED}1777 ${BLU}/tmp${NC}... "
if [ "$TEST" -eq 0 ]; then
  chmod 1777 /tmp
fi

echo -ne "${INFO}: copy backup to new ${BLU}/tmp${NC} directory... "
if [ "$TEST" -eq 0 ]; then
  mv -f /tmp.old/* /tmp/
  rmdir /tmp.old
fi
echo "Done"

echo -ne "${INFO}: add line to ${BLU}/etc/fstab${NC}... "
if [ "$TEST" -eq 0 ]; then
  echo "${TMPFILE} /tmp ext4 loop,rw,noexec,nosuid,nodev 0 0" >> /etc/fstab
fi
echo -e "Done\n"

echo -ne "All set! Result: ${BLU}"
mount | grep '/tmp'
echo -e "${NC}"
