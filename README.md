Description
===========

IPFW firewall configuration for Mac OS X 10.4 - 10.6. This is a complete package with custom launchd item and control scripts. There's also a Makefile for creating the installer package with [luggage](https://github.com/unixorn/luggage).

The rules are from:
Mac OS X Security Configuration Guide For Mac OS X Version 10.6 Snow Leopard  
<http://www.apple.com/support/security/guides/>

Combined together and slightly modified by:  
Hannes Juutilainen <hjuutilainen@mac.com>

Files and locations:
====================

* /Library/LaunchDaemons/com.github.hjuutilainen.ipfw.plist
	* Launchd item which starts the IPFW firewall on boot. Basically calls *ipfw-control.sh* with *restart* argument.
* /private/etc/ipfw/ipfw-defaultrules.conf
	* The default rules are in this file. This will get constantly overwritten by the installer, so any client specific rules should go to the custom rule file (see next).
* /private/etc/ipfw/ipfw-customrules.conf
	* The custom rule file. This file will be a part of the final ruleset so place any client specific rules here. This is dynamically created by the installer if it is missing.
* /private/etc/ipfw/customrules/
	* This is a directory which can contain custom rules as files. Intended for the situation where some third-party application requires some special firewall rules. Create a file (programmatically) in this folder and it will be included in the final ruleset.
* /usr/local/bin/ipfw-control.sh
	* Control script for the firewall. Usage: *ipfw-control.sh start|stop|restart*
* /usr/local/bin/ipfw-restart.sh
	* Helper script to quickly unload and load the launchd item. Also resets IPFW counters and displays the loaded rules.

Files used to create the installer:
===================================

* ./Makefile
	* The Makefile for [luggage](https://github.com/unixorn/luggage). To create the installer package, run *make pkg* in this directory.
* ./postflight
	* Installer postflight script. Loads the firewall if installed on startup disk.
* ./preflight
	* Installer preflight script. Unloads the launchd item (if loaded) and takes a backup of the files about to be overwritten in /var/backups/