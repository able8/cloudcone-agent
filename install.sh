#!/bin/bash
#
#===========================================================
# CloudCone - Installer v2.0
#===========================================================

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

clear

LOG=/tmp/cloudcone.log

echo "--------------------------------------"
echo " Welcome to CloudCone Agent Installer"
echo "--------------------------------------"
echo " "

if [ $(id -u) != "0" ]; then
	echo "CloudCone Agent installer needs to be installed with root priviliges"
	echo "Try again with root privilileges"
	exit 1;
fi

if [ $# -lt 1 ]; then
	echo "The CloudCone server key is missing"
	echo "Exiting installer"
	exit 1;
fi

echo "Installing Dependencies"

if [ -n "$(command -v yum)" ]; then
	yum -y install cronie gzip curl >> $LOG 2>&1
	service crond start >> $LOG 2>&1
	chkconfig crond on >> $LOG 2>&1

	if ! type "perl" >> $LOG 2>&1; then
		yum -y install perl >> $LOG 2>&1
	fi

	if ! type "unzip" >> $LOG 2>&1; then
		yum -y install unzip >> $LOG 2>&1
	fi

	if ! type "curl" >> $LOG 2>&1; then
		yum -y install curl >> $LOG 2>&1
	fi
fi

if [ -n "$(command -v apt-get)" ]; then
	apt-get update -y >> $LOG 2>&1
	apt-get install -y cron curl gzip >> $LOG 2>&1
	service cron start >> $LOG 2>&1

	if ! type "perl" >> $LOG 2>&1; then
		apt-get install -y perl >> $LOG 2>&1
	fi

	if ! type "unzip" >> $LOG 2>&1; then
		apt-get install -y unzip >> $LOG 2>&1
	fi

	if ! type "curl" >> $LOG 2>&1; then
		apt-get install -y curl >> $LOG 2>&1
	fi
fi

if [ -n "$(command -v pacman)" ]; then
	pacman -Sy  >> $LOG 2>&1
	pacman -S --noconfirm cronie curl gzip >> $LOG 2>&1
	systemctl start cronie >> $LOG 2>&1
	systemctl enable cronie >> $LOG 2>&1

	if ! type "perl" >> $LOG 2>&1; then
		pacman -S --noconfirm perl >> $LOG 2>&1
	fi

	if ! type "unzip" >> $LOG 2>&1; then
		pacman -S --noconfirm unzip >> $LOG 2>&1
	fi

	if ! type "curl" >> $LOG 2>&1; then
		pacman -S --noconfirm curl >> $LOG 2>&1
	fi
fi


if [ -n "$(command -v zypper)" ]; then
	zypper --non-interactive install cronie curl gzip >> $LOG 2>&1
	service cron start >> $LOG 2>&1

	if ! type "perl" >> $LOG 2>&1; then
		zypper --non-interactive install perl >> $LOG 2>&1
	fi

	if ! type "unzip" >> $LOG 2>&1; then
		zypper --non-interactive install unzip >> $LOG 2>&1
	fi

	if ! type "curl" >> $LOG 2>&1; then
		zypper --non-interactive install curl >> $LOG 2>&1
	fi
fi


if [ -n "$(command -v emerge)" ]; then

	if ! type "crontab" >> $LOG 2>&1; then
		emerge cronie >> $LOG 2>&1
		/etc/init.d/cronie start >> $LOG 2>&1
		rc-update add cronie default >> $LOG 2>&1
 	fi

	if ! type "perl" >> $LOG 2>&1; then
		emerge perl >> $LOG 2>&1
	fi

	if ! type "unzip" >> $LOG 2>&1; then
		emerge unzip >> $LOG 2>&1
	fi

	if ! type "curl" >> $LOG 2>&1; then
		emerge net-misc/curl >> $LOG 2>&1
	fi

	if ! type "gzip" >> $LOG 2>&1; then
		emerge gzip >> $LOG 2>&1
	fi
fi


if [ -f "/etc/slackware-version" ]; then

	if [ -n "$(command -v slackpkg)" ]; then

		if ! type "crontab" >> $LOG 2>&1; then
			slackpkg -dialog=off -batch=on -default_answer=y install dcron >> $LOG 2>&1
		fi

		if ! type "perl" >> $LOG 2>&1; then
			slackpkg -dialog=off -batch=on -default_answer=y install perl >> $LOG 2>&1
		fi

		if ! type "unzip" >> $LOG 2>&1; then
			slackpkg -dialog=off -batch=on -default_answer=y install infozip >> $LOG 2>&1
		fi

		if ! type "curl" >> $LOG 2>&1; then
			slackpkg -dialog=off -batch=on -default_answer=y install curl >> $LOG 2>&1
		fi

		if ! type "gzip" >> $LOG 2>&1; then
			slackpkg -dialog=off -batch=on -default_answer=y install gzip >> $LOG 2>&1
		fi

	else
		echo "Please install slackpkg and re-run installation."
		exit 1;
	fi
fi


if [ ! -n "$(command -v crontab)" ]; then
	echo "Cron is required but we could not install it."
	echo "Exiting installer"
	exit 1;
fi

if [  ! -n "$(command -v curl)" ]; then
	echo "CURL is required but we could not install it."
	echo "Exiting installer"
	exit 1;
fi

if [ -f /opt/cloudcone/agent.sh ]; then
	# Remove folder
	rm -rf /opt/cloudcone
	# Remove crontab
	crontab -r -u ccagent >> $LOG 2>&1
	# Remove user
	userdel ccagent >> $LOG 2>&1
fi

mkdir -p /opt/cloudcone >> $LOG 2>&1
wget -O /opt/cloudcone/agent.sh http://web.cloudc.one/sh/stats/agent.sh >> $LOG 2>&1

echo "$1" > /opt/cloudcone/serverkey
echo "http://watch.cloudc.one/agent" > /opt/cloudcone/gateway

if ! [ -f /opt/cloudcone/agent.sh ]; then
	echo "Unable to install!"
	echo "Exiting installer"
	exit 1;
fi

useradd ccagent -r -d /opt/cloudcone -s /bin/false >> $LOG 2>&1
groupadd ccagent >> $LOG 2>&1

if [ -f /usr/sbin/cagefsctl ]; then
	/usr/sbin/cagefsctl --disable ccagent >> $LOG 2>&1
fi

chown -R ccagent:ccagent /opt/cloudcone && chmod -R 700 /opt/cloudcone >> $LOG 2>&1

crontab -u ccagent -l 2>/dev/null | { cat; echo "* * * * * bash /opt/cloudcone/agent.sh > /opt/cloudcone/cron.log 2>&1"; } | crontab -u ccagent -

echo " "
echo "-------------------------------------"
echo " Installation Completed "
echo "-------------------------------------"


if [ -f $0 ]; then
	rm -f $0
fi
