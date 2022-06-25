#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

if [ ! -f /usr/bin/applydeltarpm ];then
	yum -y provides '*/applydeltarpm'
	yum -y install deltarpm
fi


setenforce 0
sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config

yum install -y wget lsof crontabs
yum install -y python3-devel
yum install -y python-devel
yum install -y vixie-cron
yum install -y curl-devel libmcrypt libmcrypt-devel

#https need
if [ ! -d /root/.acme.sh ];then	
	curl https://get.acme.sh | sh
fi

if [ -f /etc/init.d/iptables ];then

	iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
	iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
	iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
	iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 888 -j ACCEPT
	iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 7200 -j ACCEPT
	# iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 3306 -j ACCEPT
	# iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 30000:40000 -j ACCEPT
	service iptables save

	iptables_status=`service iptables status | grep 'not running'`
	if [ "${iptables_status}" == '' ];then
		service iptables restart
	fi

	#安装时不开启
	service iptables stop
fi


if [ ! -f /etc/init.d/iptables ];then
	yum install firewalld -y
	systemctl enable firewalld
	systemctl start firewalld

	firewall-cmd --permanent --zone=public --add-port=22/tcp
	firewall-cmd --permanent --zone=public --add-port=80/tcp
	firewall-cmd --permanent --zone=public --add-port=443/tcp
	firewall-cmd --permanent --zone=public --add-port=888/tcp
	firewall-cmd --permanent --zone=public --add-port=7200/tcp
	# firewall-cmd --permanent --zone=public --add-port=3306/tcp
	# firewall-cmd --permanent --zone=public --add-port=30000-40000/tcp


	sed -i 's#AllowZoneDrifting=yes#AllowZoneDrifting=no#g' /etc/firewalld/firewalld.conf
	firewall-cmd --reload
fi


#安装时不开启
systemctl stop firewalld

yum groupinstall -y "Development Tools"
yum install -y epel-release

yum install -y oniguruma oniguruma-devel
#centos8 stream | use dnf
if [ "$?" != "0" ];then
	yum install -y dnf dnf-plugins-core
	dnf config-manager --set-enabled powertools
	yum install -y oniguruma oniguruma-devel
fi

yum install -y libevent libevent-devel libjpeg* libpng* gd* libxslt* unzip
yum install -y python-imaging libicu-devel zip bzip2-devel gcc libxml2 libxml2-devel  pcre pcre-devel
yum install -y libjpeg-devel libpng-devel libwebp libwebp-devel
yum install -y lsof net-tools
yum install -y ncurses-devel cmake
yum install -y MySQL-python 



if [ ! -f /usr/local/bin/pip3 ];then
    python3 -m pip install --upgrade pip setuptools wheel -i https://mirrors.aliyun.com/pypi/simple
fi


# echo  "start install lib"
cd /www/server/mdserver-web/scripts && bash lib.sh
# echo  "end install lib"


chmod 755 /www/server/mdserver-web/data


# echo  "start install python lib"

pip install --upgrade pip
pip3 install gunicorn==20.1.0
pip3 install gevent==21.1.2
pip3 install gevent-websocket==0.10.1
pip3 install requests==2.20.0
pip3 install flask-caching==1.10.1
pip3 install psutil==5.9.1 
pip3 install pymongo

cd /www/server/mdserver-web && pip3 install -r /www/server/mdserver-web/requirements.txt


# echo  "start install python env lib"

if [ ! -f /www/server/mdserver-web/bin/activate ];then
	cd /www/server/mdserver-web && python3 -m venv .
	source /www/server/mdserver-web/bin/activate
	pip install --upgrade pip
	pip3 install -r /www/server/mdserver-web/requirements.txt
	pip3 install gunicorn==20.1.0
	pip3 install gevent==21.1.2
	pip3 install gevent-websocket==0.10.1
	pip3 install requests==2.20.0
	pip3 install flask-caching==1.10.1
	pip3 install flask-session==0.3.2
	pip3 install flask-sqlalchemy==2.3.2
	pip3 install psutil==5.9.1
	pip3 install pymongo
fi

# echo  "end install python env lib"
# echo  "end install python lib"


cd /www/server/mdserver-web && ./cli.sh start
sleep 5

cd /www/server/mdserver-web && ./cli.sh stop
cd /www/server/mdserver-web && ./scripts/init.d/mw default
cd /www/server/mdserver-web && ./cli.sh start