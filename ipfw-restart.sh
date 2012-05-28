#!/bin/bash

# ==============================================================================
#   ipfw-restart.sh
#
#   Restart ipfw firewall and display rules
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

# Change to match the actual item (if needed):
LAUNCHD_ITEM_NAME="com.github.hjuutilainen.ipfw"

LAUNCHCTL="/bin/launchctl"
IPFW="/sbin/ipfw"
IPFW_LAUNCHD_ITEM="/Library/LaunchDaemons/$LAUNCHD_ITEM_NAME.plist"

# Check for root
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 2>&1
	exit 1

else
	if [[ -f "$IPFW_LAUNCHD_ITEM" ]]; then
		
		# Unload the launchd item if already loaded
		$LAUNCHCTL list $LAUNCHD_ITEM_NAME
		if [[ $? -eq 0 ]]; then
			echo ""
			echo "# Unloading $IPFW_LAUNCHD_ITEM"
	    	$LAUNCHCTL unload "$IPFW_LAUNCHD_ITEM"
		fi

		# Flush existing rules
		echo "# Flushing old rules"
		$IPFW -q flush

		# Load the launchd item
		echo "# Loading $IPFW_LAUNCHD_ITEM"
		$LAUNCHCTL load -w $IPFW_LAUNCHD_ITEM

		# Reset the counters
		echo "# Resetting counters"
		$IPFW -q zero

		# Show current rules
		sleep 1
		echo "# Current active rules:"
		$IPFW -N show
		
	else
		echo "$IPFW_LAUNCHD_ITEM not found" 2>&1
		exit 1
	fi
fi
