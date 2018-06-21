# autoinstall-nagioscore
Autoinstall-nagioscore is a shell script that automatically downloads and installs Nagios Core, the free and open source network monitoring software.

## Installation

To install Nagios Core using the autoinstall-nagioscore script just run the following two commands and enjoy. During the installation there will be a password prompt, this sets the password for the Nagios web interface.

```
wget https://raw.githubusercontent.com/aschbacd/autoinstall-nagioscore/master/autoinstall-nagioscore.sh
bash autoinstall-nagioscore.sh
```

### What will be installed?
* Nagios Core 4.4.0
* Nagios Plugins 2.2.1
* NRPE (optional)
* custom config with predone folder structure (optional)

### Tested linux distributions
* Debian 9.4

## References

[Nagios Core] https://github.com/NagiosEnterprises/nagioscore

[Nagios Plugins] https://github.com/nagios-plugins/nagios-plugins

[NRPE] https://github.com/NagiosEnterprises/nrpe

[Manual Installation] https://linoxide.com/monitoring-2/install-nagios-4-debian-9/
