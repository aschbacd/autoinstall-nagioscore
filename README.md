# autoinstall-nagioscore
Autoinstall-nagioscore is a shell script that automatically downloads and installs Nagios Core, the free and open source network monitoring software.

## Installation

To install Nagios Core using the autoinstall-nagioscore script just run the following two commands and enjoy. Note: During the installation some prompts will appear that require user input.

```bash
wget https://raw.githubusercontent.com/aschbacd/autoinstall-nagioscore/master/autoinstall-nagioscore.sh
bash autoinstall-nagioscore.sh
```

or

```bash
bash <(curl -s https://raw.githubusercontent.com/aschbacd/autoinstall-nagioscore/master/autoinstall-nagioscore.sh)
```

The script will create 2 new files called `autoinstall-nagioscore.error` and `autoinstall-nagioscore.log`, placed in the same folder the script is being executed. Those files contain all log information and can be monitored in another session using the following command:

```bash
tail -f autoinstall-nagioscore.log
tail -f autoinstall-nagioscore.error
```

### What will be installed?
* Nagios Core 4.4.3
* Nagios Plugins 2.2.1
* NRPE (optional)
* custom config with predone folder structure (optional)

### Tested linux distributions
* Debian 9.4
* Debian 9.8
* CentOS 7.5.1804 (Infrastructure Server)
* Fedora Server 25 (1.3)

## References

[Nagios Core] https://github.com/NagiosEnterprises/nagioscore

[Nagios Plugins] https://github.com/nagios-plugins/nagios-plugins

[NRPE] https://github.com/NagiosEnterprises/nrpe

[Manual Installation] https://linoxide.com/monitoring-2/install-nagios-4-debian-9/
