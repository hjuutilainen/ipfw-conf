#!/bin/bash

# ==============================================================================
#   ipfw-control.sh
#
#   Control script for ipfw firewall
#   Copyright 2012 Hannes Juutilainen <hjuutilainen@mac.com>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
# ==============================================================================

# Declare variables
CONF_DIR="/etc/ipfw"
CONF_DIR_CUSTOM="/etc/ipfw/customrules"
DEFAULT_RULES='/etc/ipfw/ipfw-defaultrules.conf'
CUSTOM_RULES='/etc/ipfw/ipfw-customrules.conf'
IPFW="/sbin/ipfw"
ECHO="/bin/echo"
STAT="/usr/bin/stat"
PRINTF="/usr/bin/printf"
SYSCTL="/usr/sbin/sysctl"
OP_MODE="restart"

# ========================================
function usage () {
# ========================================
	echo ""
	echo "$0 [-h|--help|h] [start|stop|restart]"
	echo ""
	echo "Where:"
	echo "-h|--help|h   Print this message"
	echo "start         Start the firewall (without flushing)"
	echo "stop          Stop the firewall and flush rules"
	echo "restart       Flush and re-read all rules and restart firewall"
	exit
}

# ========================================
function checkFilePerms () {
# ========================================
	FILESTATS=`$STAT -f "%Su:%Sg, %SHp%SMp%SLp" "$1"`
	if [[ $FILESTATS != "root:wheel, rw-r--r--" ]]; then
		return 1
	else
		return 0
	fi
}

# ========================================
function checkDirectoryPerms () {
# ========================================
	FILESTATS=`$STAT -f "%Su:%Sg, %SHp%SMp%SLp" "$1"`
	if [[ $FILESTATS != "root:wheel, rwxr-xr-x" ]]; then
		return 1
	else
		return 0
	fi
}

# ========================================
function verifyFiles () {
# ========================================
	$ECHO ""
	$ECHO "Verifying configuration security:"
	
	FORMAT="%-40s%-10s\n"
	INSECURE="Failed (Insecure, will not be loaded)"
	VERIFIED="OK"
	NOT_FOUND="Failed (No such file or directory)"
	OBJECT=""
	RESULT=""
	
	OBJECT=$CONF_DIR
	if [[ -d "$CONF_DIR" ]]; then
		if checkDirectoryPerms "$CONF_DIR"; then
			RESULT=$VERIFIED
		fi
	else
		RESULT=$NOT_FOUND
	fi
	$PRINTF "$FORMAT" "$OBJECT" "$RESULT"
	
	OBJECT=$CONF_DIR_CUSTOM
	if [[ -d "$CONF_DIR_CUSTOM" ]]; then
		if checkDirectoryPerms "$CONF_DIR_CUSTOM"; then
			RESULT=$VERIFIED
		fi
	else
		RESULT=$NOT_FOUND
	fi
	$PRINTF "$FORMAT" "$OBJECT" "$RESULT"
	
	OBJECT=$DEFAULT_RULES
	if [[ -f "$DEFAULT_RULES" ]]; then
		if checkFilePerms "$DEFAULT_RULES"; then
			RESULT=$VERIFIED
			$PRINTF "$FORMAT" "$OBJECT" "$RESULT"
		fi
	fi
	
	OBJECT=$CUSTOM_RULES
	if [[ -f "$CUSTOM_RULES" ]]; then
		if checkFilePerms "$CUSTOM_RULES"; then
			RESULT=$VERIFIED
		else
			RESULT=$INSECURE
		fi
	else
		RESULT=$NOT_FOUND
	fi
	$PRINTF "$FORMAT" "$OBJECT" "$RESULT"
	
	
	shopt -s nullglob
	DID_FIND_CUSTOMRULE_FILES=0
	CUSTOM_RULES=/etc/ipfw/customrules/*
	for f in $CUSTOM_RULES
	do
		OBJECT=$f
		if checkFilePerms "$f"; then
			RESULT=$VERIFIED
			DID_FIND_CUSTOMRULE_FILES=1
		else
			RESULT=$INSECURE
		fi
		$PRINTF "$FORMAT" "$OBJECT" "$RESULT"
	done
	shopt -u nullglob
}

# ========================================
function loadDefaultRules () {
# ========================================
	$ECHO ""
	$ECHO "Loading default rules:"
	if [[ -f "$DEFAULT_RULES" ]]; then
		if checkFilePerms "$DEFAULT_RULES"; then
			$ECHO "---> $DEFAULT_RULES"
			$IPFW "$DEFAULT_RULES" > /dev/null 2>&1
		else
			exit 1
		fi
	else
		$ECHO "---> $DEFAULT_RULES, no such file"
	fi
}

# ========================================
function loadCustomRules () {
# ========================================
	if [[ -f "$CUSTOM_RULES" ]]; then
		$ECHO ""
		$ECHO "Loading $CUSTOM_RULES:"
		if checkFilePerms "$CUSTOM_RULES"; then
			$ECHO "---> $CUSTOM_RULES"
			$IPFW "$CUSTOM_RULES" > /dev/null 2>&1
		fi
	fi
	$ECHO ""
	$ECHO "Loading rule files in /etc/ipfw/customrules/"
	shopt -s nullglob
	DID_FIND_CUSTOMRULE_FILES=0
	CUSTOM_RULES=/etc/ipfw/customrules/*
	for f in $CUSTOM_RULES
	do
		if checkFilePerms "$f"; then
			$ECHO "---> $f"
			$IPFW "$f" > /dev/null 2>&1
			DID_FIND_CUSTOMRULE_FILES=1
		fi
	done
	shopt -u nullglob
	[ $DID_FIND_CUSTOMRULE_FILES -eq 0 ] && $ECHO "---> Directory is empty"
}

# ========================================
function flushAllRules () {
# ========================================
	$ECHO ""
	$ECHO "Flushed all rules"
	$IPFW -qf flush
}

# ========================================
function showCurrentRules () {
# ========================================
	$ECHO ""
	$IPFW -qf zero
	$ECHO "Current rules:"
	$IPFW -N show
}

# ========================================
function configureKernelParameters () {
# ========================================
	$SYSCTL -w net.inet.ip.fw.enable=1 > /dev/null 2>&1
	$SYSCTL -w net.inet.ip.fw.verbose=2 > /dev/null 2>&1
	$SYSCTL -w net.inet.ip.fw.verbose_limit=0 > /dev/null 2>&1
	$SYSCTL -w net.inet.ip.forwarding=0 > /dev/null 2>&1
}


while test -n "$1"; do
  case $1 in 
	-h|--help|h) 
		usage
	;;
	start) 
		OP_MODE="start"
		shift
	;;
	stop) 
		OP_MODE="stop"
		shift
	;;
	restart)
		OP_MODE="restart"
		shift
	;;	 
	*) 
		usage
	;; 
  esac
done

# Check for root
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 2>&1
	exit 1
else
	verifyFiles
	
	if [[ $OP_MODE == "start" ]]; then
		configureKernelParameters
		loadDefaultRules
		loadCustomRules
		showCurrentRules
	
	elif [[ $OP_MODE == "stop" ]]; then
		flushAllRules
		showCurrentRules
	
	elif [[ $OP_MODE == "restart" ]]; then
		configureKernelParameters
		flushAllRules
		loadDefaultRules
		loadCustomRules
		showCurrentRules
	
	else
		echo "Unknown operation mode..."
		usage
		exit 1
	fi
fi

exit 0
