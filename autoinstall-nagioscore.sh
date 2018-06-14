#!/bin/bash
# created by aschbacd - 06/14/2018

# ///// ******************** NAGIOS4 INSTALLATION ******************** ///// #

# install prerequisites
apt install -y apache2 apache2-utils php build-essential autoconf gcc libc6 make wget unzip libgd2-xpm-dev

# add nagios user & group
useradd nagios && groupadd nagcmd
usermod -a -G nagcmd nagios && usermod -a -G nagcmd www-data

# download and extract nagios4
mkdir /opt/nagios
cd /opt/nagios
wget -O nagioscore.tar.gz https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-4.3.4/nagios-4.3.4.tar.gz
tar xzf nagioscore.tar.gz
cd nagios-4.3.4

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

# install nagios4 plugins
apt install -y autoconf gcc libc6 libmcrypt-dev make libssl-dev wget bc gawk dc build-essential snmp libnet-snmp-perl gettext
cd /opt/nagios
wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz
tar zxf nagios-plugins.tar.gz
cd nagios-plugins-release-2.2.1
./tools/setup
./configure
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
read -p "Do you want to install the nrpe plugin? [Y/n]: " config
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