#!/bin/bash

RED='\033[01;31m'
GREEN='\033[01;32m'
RESET='\033[0m'
IP_LIST=$(for i in `/sbin/ifconfig | grep Bcast | awk '{ print $2}' |cut -d ":" -f2` ; do echo -n "$i " ; done)
if [[ `/usr/local/apache/bin/httpd -v|grep version|cut -d\/ -f2|awk '{print $1}'|grep '2.4'` ]];then
	echo "installing remote IP module for apache 2.4" 
	wget -c https://github.com/bashcode/mod_rpaf/blob/master/mod_remoteip.c
	/usr/local/apache/bin/apxs -c -i -a  mod_remoteip.c
	/usr/local/cpanel/scripts/rebuildhttpdconf
	IPLIST=$(/usr/local/cpanel/scripts/ipusage | awk '{print $1}' | while read ip; do echo -ne "RemoteIPInternalProxy ${ip}\n"; done)
	if grep "mod_rpaf.conf"  /usr/local/apache/conf/includes/pre_main_global.conf ; then
cat > /usr/local/apache/conf/mod_rpaf.conf << EOF
LoadModule remoteip_module    modules/mod_remoteip.so
RemoteIPHeader X-Real-IP
RemoteIPInternalProxy 127.0.0.1
$IPLIST
EOF

	else
cat > /usr/local/apache/conf/mod_rpaf.conf << EOF
LoadModule remoteip_module    modules/mod_remoteip.so
RemoteIPHeader X-Real-IP
RemoteIPInternalProxy 127.0.0.1
$IPLIST
EOF
	echo "Include \"/usr/local/apache/conf/mod_rpaf.conf\""  >> /usr/local/apache/conf/includes/pre_main_global.conf
	fi
	

else
export modarp="mod_rpaf-2.0.c"
	export libname="mod_rpaf-2.0.so"
	cd /usr/local/src
	rm -rf mod_rpaf*
	wget -c  https://github.com/bashcode/mod_rpaf/blob/master/mod_rpaf.2.4.tar.gz
	tar -xzf mod_rpaf.2.4.tar.gz
	cd mod_rpaf/
	/usr/local/apache/bin/apxs -cia $modarp
	/usr/local/cpanel/scripts/rebuildhttpdconf
	IP_LIST=$(for i in `/sbin/ifconfig | grep Bcast | awk '{ print $2}' |cut -d ":" -f2` ; do echo -n "$i " ; done)
	if grep "mod_rpaf.conf"  /usr/local/apache/conf/includes/pre_main_global.conf ; then
cat > /usr/local/apache/conf/mod_rpaf.conf << EOF
LoadModule rpaf_module        modules/$libname
RPAFenable On
RPAFproxy_ips $IP_LIST
RPAFsethostname On
RPAFheader X-Real-IP
EOF
	else
cat > /usr/local/apache/conf/mod_rpaf.conf << EOF
LoadModule rpaf_module        modules/$libname
RPAFenable On
RPAFproxy_ips $IP_LIST
RPAFsethostname On
RPAFheader X-Real-IP
EOF
echo "Include \"/usr/local/apache/conf/mod_rpaf.conf\""  >> /usr/local/apache/conf/includes/pre_main_global.conf
	fi
fi
/usr/local/cpanel/scripts/restartsrv_httpd
