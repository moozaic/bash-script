#!/usr/bin/env bash
#
###############################
# DEBIAN 8.x SETUP
#
###############################
SETUP_TMP=/opt


codename=`lsb_release --codename | cut -f2`

echo $codename

# remove systemd
# ---
#apt-get install sysvinit-core sysvinit-utils
# edit grub
# copy -> GRUB_CMDLINE_LINUX_DEFAULT=""
#update-grub
#reboot
#echo -e 'Package: systemd\nPin: release *\nPin-Priority: -1' > /etc/apt/preferences.d/systemd
#echo -e '\n\nPackage: *systemd*\nPin: release *\nPin-Priority: -1' >> /etc/apt/preferences.d/systemd
#echo -e '\nPackage: systemd:amd64\nPin: release *\nPin-Priority: -1' >> /etc/apt/preferences.d/systemd
#echo -e '\nPackage: systemd:i386\nPin: release *\nPin-Priority: -1' >> /etc/apt/preferences.d/systemd

# NGINX
cd $SETUP_TMP
wget http://nginx.org/keys/nginx_signing.key
apt-key add nginx_signing.key
rm -f nginx_signing.key
echo "deb-src http://nginx.org/packages/debian/ $codename nginx" >> /etc/apt/sources.list


# UPDATE
apt-get update
# UPGRADE
apt-get upgrade -y
# INSTALL
apt-get install wget curl make gcc python2.7 python-dev build-essential libgd-dev libgeoip-dev checkinstall git libgd2-xpm-dev libgeoip-dev libxslt-dev zlib1g-dev autoconf libtool tcl8.5 php5-dev


# LIBSODIUM
cd opt/
wget https://download.libsodium.org/libsodium/releases/LATEST.tar.gz
tar zxvf LATEST.tar.gz


# LIMITS
echo "*         hard    nofile      500000" >> /etc/security/limits.conf
echo "*         soft    nofile      500000" >> /etc/security/limits.conf
echo "root      hard    nofile      500000" >> /etc/security/limits.conf
echo "root      soft    nofile      500000" >> /etc/security/limits.conf


