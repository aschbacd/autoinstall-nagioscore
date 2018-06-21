#!/bin/bash
# created by aschbacd - 06/14/2018

# ///// ******************** FUNCTIONS ******************** ///// #

function print_installing {
        echo -en "[ ...... ] - installing package $1"
}

function print_installed {
        if [ $1 -eq 0 ] ; then
                echo -en "\r[   \e[32mOK\e[0m   ] - $2 installed successfully"
        else
                echo -en "\r[ \e[31mFAILED\e[0m ] - $2 could not be installed"
        fi
        echo
}

function install_package {
        print_installing $1
        apt-get install -y $1 1>>install.log 2>>install.error
        print_installed $? $1
}

# ///// ******************** NAGIOS4 INSTALLATION ******************** ///// #

# install dependencies
install_package apache2
install_package apache2-utils
install_package php
install_package build-essential
install_package autoconf
install_package gcc
install_package libc6
install_package make
install_package wget
install_package unzip
install_package libgd2-xpm-dev

# add nagios user & group
useradd nagios && groupadd nagcmd
usermod -a -G nagcmd nagios && usermod -a -G nagcmd www-data

# download and extract nagios4
mkdir /opt/nagios
cd /opt/nagios
wget -O nagioscore.tar.gz https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-4.4.0/nagios-4.4.0.tar.gz
tar xzf nagioscore.tar.gz
cd nagios-4.4.0

# install and configure nagios4
./configure --with-nagios-group=nagios --with-command-group=nagcmd --with-httpd_conf=/etc/apache2/sites-enabled/
make all
make install
make install-init
make install-commandmode
make install-config
make install-webconf
a2enmod rewrite && a2enmod cgi

# nagios4 web interface
htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin
systemctl restart apache2.service

# ///// ******************** NAGIOS4 PLUGINS ******************** ///// #

# install dependencies
install_package libmcrypt-dev
install_package libssl-dev
install_package bc
install_package gawk
install_package dc
install_package snmp
install_package libnet-snmp-perl
install_package gettext

# download nagios4 plugins
cd /opt/nagios
wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz
tar zxf nagios-plugins.tar.gz
cd nagios-plugins-release-2.2.1
./tools/setup
./configure

# compile nagios4 plugins
make
make install

# start nagios
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
systemctl enable nagios
systemctl reload nagios
systemctl start nagios

# ///// ******************** [OPTIONAL] NAGIOS4 NRPE PLUGIN ******************** ///// #

function install_nrpe {
	mkdir /opt/nagios/
	cd /opt/nagios/
	wget -O nagios-nrpe.tar.gz https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-3.2.1/nrpe-3.2.1.tar.gz
	tar xzf nagios-nrpe.tar.gz
	cd nrpe-3.2.1/
	./configure
	make check_nrpe
	make install-plugin
}

echo -e "\n"
read -p "Do you want to install the nrpe plugin? [Y/n]: " nrpe
if [ $nrpe ] ; then
	loop=true
	while [ $loop == true ] ; do
		case "$nrpe" in
			[yY] | [yY][eE][sS])
				install_nrpe
				loop=false
				;;
			[nN] | [nN][oO])
				loop=false
				;;
			*)
				echo "[Error] Please enter yes or no."
				;;
		esac
		if [ $loop == true ] ; then
			read -p "Do you want to install the nrpe plugin? [Y/n]: " nrpe
		fi
	done
else
	install_nrpe
fi

# ///// ******************** [OPTIONAL] LOAD CUSTOM CONFIGURATION ******************** ///// #

function load_configuration {
	mkdir /opt/nagios/
	cd /opt/nagios/
	wget https://github.com/aschbacd/autoinstall-nagioscore/releases/download/1.0/config.tar.gz
	tar xzf config.tar.gz
	cd /usr/local/nagios/etc/
	rm -r objects cgi.cfg nagios.cfg resource.cfg
	cd /opt/nagios/config/
	mv objects /usr/local/nagios/etc/
	mv cgi.cfg /usr/local/nagios/etc/
	mv nagios.cfg /usr/local/nagios/etc/
	mv resource.cfg /usr/local/nagios/etc/
	systemctl restart nagios
}

echo -e "\n"
read -p "Do you want to load the custom configuration? [Y/n]: " config
if [ $config ] ; then
	loop=true
	while [ $loop == true ] ; do
		case "$config" in
			[yY] | [yY][eE][sS])
				load_configuration
				loop=false
				;;
			[nN] | [nN][oO])
				loop=false
				;;
			*)
				echo "[Error] Please enter yes or no."
				;;
		esac
		if [ $loop == true ] ; then
			read -p "Do you want to load the custom configuration? [Y/n]: " config
		fi
	done
else
	load_configuration
fi
