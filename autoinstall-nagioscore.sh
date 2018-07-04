#!/bin/bash
# created by aschbacd - 06/14/2018

# ///// ******************** FUNCTIONS ******************** ///// #

function determine_package_manager {
	declare -A osInfo;
	osInfo[/etc/redhat-release]=yum
	osInfo[/etc/arch-release]=pacman
	osInfo[/etc/gentoo-release]=emerge
	osInfo[/etc/SuSE-release]=zypp
	osInfo[/etc/debian_version]=apt-get

	for f in ${!osInfo[@]}
	do
		if [[ -f $f ]];then
			package_manager=${osInfo[$f]}
		fi
	done
}

function print_start {
	# PARAMETER 01 ... text (what will happen)
	
	echo -en "[ ...... ] $1"
}

function print_finished {
	# PARAMETER 01 ... 0 or 1 -> succeeded or failed
	# PARAMETER 02 ... text if succeeded
	# PARAMETER 03 ... text if failed
	
	if [ $1 -eq 0 ] ; then
		echo -en "\r[   \e[32mOK\e[0m   ] $2"
	else
		echo -en "\r[ \e[31mFAILED\e[0m ] $3"
	fi
	
	echo
}

function execute {
	# PARAMETER 01 ... text (what will happen)
	# PARAMETER 02 ... text if succeeded
	# PARAMETER 03 ... text if failed
	# PARAMETER 04 ... critical command -> 0 ... yes / 1 ... no
	# PARAMETER 05 ... command that will be executed
	# PARAMETER 06 ... command that checks if first command worked (optional)
	
	print_start "$1"
	
	eval $5 1>>"$base_dir/autoinstall-nagioscore.log" 2>>"$base_dir/autoinstall-nagioscore.error"
	exit_code=$?
	if [ $# -eq 6 ] ; then
		eval $6 1>>"$base_dir/autoinstall-nagioscore.log" 2>>"$base_dir/autoinstall-nagioscore.error"
		exit_code=$?
	fi
	
	print_finished $exit_code "$2" "$3"
	
	# stop script if critical error
	if [ $4 -eq 0 ] && [ $exit_code -ne 0 ] ; then
		echo "[  INFO  ] script had to be stopped due to a fatal error"
		exit 1
	fi
}

function install_package {
	# PARAMETER 01 ... package name
	# PARAMETER 02 ... critical command -> 0 ... yes / 1 ... no
	if [ $package_manager == "yum" ] ; then
		package_check="yum list installed $1"
	elif [ $package_manager == "apt-get" ] ; then
		package_check="dpkg -s $1"
	fi
	execute "installing package $1" "package $1 installed successfully" "package $1 could not be installed" $2 "$package_manager install -y $1" $package_check
}

function create_directory {
	# PARAMETER 01 ... directory path
	# PARAMETER 02 ... directory name
	execute "creating $2" "$2 created successfully" "$2 could not be created" 0 "mkdir $1" "[ -d \"$1\" ]"
}

function download_file {
	# PARAMETER 01 ... filename
	# PARAMETER 02 ... download url
	execute "downloading file $1" "$1 downloaded successfully" "$1 could not be downloaded" 0 "wget -O $1 $2" "[ -f \"$1\" ]"
}

function extract_file {
	# PARAMETER 01 ... file to be extracted
	# PARAMETER 02 ... folder to check for
	execute "extracting file $1" "$1 extracted successfully" "$1 could not be extracted" 0 "tar xzvf $1" "[ -d \"$2\" ]"
}

function restart_service {
	# PARAMETER 01 ... service name
	# PARAMETER 02 ... critical command -> 0 ... yes / 1 ... no
	execute "restarting service $1" "service $1 restarted successfully" "service $1 could not be restarted" $2 "systemctl restart $1"
}


# ///// ******************** INITIAL SETUP ******************** ///// #
base_dir=$(pwd)
determine_package_manager
echo "[  INFO  ] package manger $package_manager is being used for all package installations"


# ///// ******************** NAGIOS4 INSTALLATION ******************** ///// #

# install dependencies

if [ $package_manager == "yum" ] ; then
	# redhat based
	install_package httpd 0
	install_package glibc 0
	install_package glibc-common 0
	install_package perl 0
	install_package gd 0
	install_package gd-devel 0
	install_package zip 0
elif [ $package_manager == "apt-get" ] ; then
	# debian based
	install_package apache2 0
	install_package apache2-utils 0
	install_package build-essential 0
	install_package autoconf 0
	install_package libc6 0
	install_package libgd-dev 0
fi

install_package php 0
install_package gcc 0
install_package unzip 0
install_package wget 0
install_package make 0

# add nagios user
execute "adding user nagios" "user nagios added successfully" "user nagios could not be added" 0 "useradd nagios" "id -u nagios"

# add nagios group
execute "adding group nagcmd" "group nagcmd added successfully" "group nagcmd could not be added" 0 "groupadd nagcmd" "grep -q nagcmd /etc/group"

# add nagios to nagcmd
execute "adding nagios to nagcmd" "user nagios successfully added to nagcmd" "user nagios could not be added to nagcmd" 0 "usermod -a -G nagcmd nagios" "groups nagios | grep -w nagcmd"

# add apache user to nagcmd
if [ $package_manager == "yum" ] ; then
	execute "adding www-data to nagcmd" "user www-data successfully added to nagcmd" "user www-data could not be added to nagcmd" 1 "usermod -a -G nagcmd apache" "groups apache | grep -w nagcmd"
elif [ $package_manager == "apt-get" ] ; then
	execute "adding www-data to nagcmd" "user www-data successfully added to nagcmd" "user www-data could not be added to nagcmd" 1 "usermod -a -G nagcmd www-data" "groups www-data | grep -w nagcmd"
fi

# download and extract nagios4
create_directory "/opt/nagios" "nagios download folder"
cd /opt/nagios
download_file "nagioscore.tar.gz" "https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-4.4.1/nagios-4.4.1.tar.gz"
extract_file "nagioscore.tar.gz" "nagios-4.4.1"
cd nagios-4.4.1

# install and configure nagios4
if [ $package_manager == "yum" ] ; then
	execute "configuring nagios4" "nagios4 configured successfully" "nagios4 could not be configured" 0 "./configure --with-nagios-group=nagios --with-command-group=nagcmd"
elif [ $package_manager == "apt-get" ] ; then
	execute "configuring nagios4" "nagios4 configured successfully" "nagios4 could not be configured" 0 "./configure --with-nagios-group=nagios --with-command-group=nagcmd --with-httpd_conf=/etc/apache2/sites-enabled/"
fi

execute "compiling nagios4" "nagios4 compiled successfully" "nagios4 could not be compiled" 0 "make all && make install && make install-init && make install-commandmode && make install-config && make install-webconf && make install-exfoliation"
if [ $package_manager == "apt-get" ] ; then
	execute "enabling apache2 modules" "apache2 modules enabled successfully" "apache2 modules could not be enabled" 0 "a2enmod rewrite && a2enmod cgi"
fi

# nagios4 web interface
loop=true
while [ $loop == true ] ; do
	password1=$(whiptail --passwordbox $error"Enter a password for the nagios web interface." 8 78 3>&1 1>&2 2>&3)
	password2=$(whiptail --passwordbox "Retype your password." 8 78 3>&1 1>&2 2>&3)
	if [ ! $password1 ] || [ ! $password2 ] || [ $password1 == "" ] || [ $password2 == "" ] ; then
		whiptail --ok-button "Retry" --msgbox "Password can't be empty!" 10 30
	elif [ $password1 == $password2 ] ; then
		loop=false
	else
		whiptail --ok-button "Retry" --msgbox "Passwords don't match" 10 30
	fi
done

execute "setting apache2 nagios admin user" "nagios admin user set successfully" "nagios admin user could not be set" 0 "htpasswd -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin $password1"

if [ $package_manager == "yum" ] ; then
	execute "starting service httpd" "service httpd started successfully" "service httpd could not be started" 0 "service httpd start && chkconfig httpd on"
elif [ $package_manager == "apt-get" ] ; then
	restart_service "apache2" 0
fi


# ///// ******************** NAGIOS4 PLUGINS ******************** ///// #

# install dependencies
if [ $package_manager == "yum" ] ; then
	install_package automake 0
	install_package openssl-devel 0
elif [ $package_manager == "apt-get" ] ; then
	install_package libmcrypt-dev 0
	install_package libssl-dev 0
	install_package bc 0
	install_package gawk 0
	install_package dc 0
	install_package snmp 0
	install_package libnet-snmp-perl 0
	install_package gettext 0
fi

# download nagios4 plugins
cd /opt/nagios
download_file "nagios-plugins.tar.gz" "https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz"
extract_file "nagios-plugins.tar.gz" "nagios-plugins-release-2.2.1"
cd nagios-plugins-release-2.2.1

# configure nagios4 plugins
execute "configuring nagios4 plugins" "nagios4 plugins configured successfully" "nagios4 plugins could not be configured" 0 "./tools/setup && ./configure"

# compile nagios4 plugins
execute "compiling nagios4 plugins" "nagios4 plugins compiled successfully" "nagios4 plugins could not be compiled" 0 "make && make install"

# start nagios
execute "starting service nagios" "service nagios started successfully" "service nagios could not be started" 0 "/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg && systemctl enable nagios ; systemctl reload nagios ; systemctl start nagios"

# configuring selinux & firewall
if [ $package_manager == "yum" ] ; then
	execute "disabling selinux" "selinux disabled successfully" "selinux could not be disabled" 0 "setenforce 0"
	execute "adding firewall service http" "http successfully added to firewall" "http could not be added to firewall" 0 "firewall-cmd --permanent --add-service=http"
	execute "reloading firewall" "firewall reloaded successfully" "firewall could not be reloaded" 0 "firewall-cmd --reload"
	execute "adding firewall port 80" "port 80 successfully added to firewall" "port 80 could not be added to firewall" 1 "iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT ; systemctl stop firewalld ; systemctl mask firewalld"
fi

# ///// ******************** [OPTIONAL] NAGIOS4 NRPE PLUGIN ******************** ///// #

if (whiptail --title "Nagios4 NRPE Plugin" --yesno "Do you want to install the Nagios Remote Plugin Executor on your machine, so that you can run script on another system?" 8 78) then
	cd /opt/nagios/
	download_file "nagios-nrpe.tar.gz" "https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-3.2.1/nrpe-3.2.1.tar.gz"
	extract_file "nagios-nrpe.tar.gz" "nrpe-3.2.1"
	cd nrpe-3.2.1/
	execute "configuring nrpe plugin" "nrpe plugin configured successfully" "nrpe plugin could not be configured" 0 "./configure"
	execute "compiling nrpe plugin" "nrpe plugin compiled successfully" "nrpe plugin could not be compiled" 0 "make check_nrpe && make install-plugin"
	restart_service "nagios" 0
fi

# ///// ******************** [OPTIONAL] LOAD PREDONE CONFIGURATION ******************** ///// #

if (whiptail --title "Load predone configuration" --yesno "Do you want to load the predone configuration that contains a better organized folder structure for your nagios configuration files?" 8 78) then
	cd /opt/nagios/
	download_file "config.tar.gz" "https://github.com/aschbacd/autoinstall-nagioscore/releases/download/v4.4.1/config.tar.gz"
	extract_file "config.tar.gz" "config"
	cd /usr/local/nagios/etc/
	execute "removing old configuration" "old configuration removed successfully" "old configuration could not be removed" 0 "rm -r objects cgi.cfg nagios.cfg resource.cfg"
	cd /opt/nagios/config/
	execute "applying new configuration" "new configuration applied successfully" "new configuration could not be applied" 0 "mv objects /usr/local/nagios/etc/ && mv cgi.cfg /usr/local/nagios/etc/ && mv nagios.cfg /usr/local/nagios/etc/ && mv resource.cfg /usr/local/nagios/etc/"
	restart_service "nagios" 0
fi

echo "[  INFO  ] nagios has been installed correctly"
echo "[  INFO  ] configuration folder: /usr/local/nagios"
echo "[  INFO  ] web interface user: nagiosadmin"
