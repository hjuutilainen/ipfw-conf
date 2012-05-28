#
#	Copyright 2012 Hannes Juutilainen <hjuutilainen@mac.com>
#
#	Licensed under the Apache License, Version 2.0 (the "License");
#	you may not use this file except in compliance with the License.
#	You may obtain a copy of the License at
#
#		http://www.apache.org/licenses/LICENSE-2.0
#
#	Unless required by applicable law or agreed to in writing, software
#	distributed under the License is distributed on an "AS IS" BASIS,
#	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#	See the License for the specific language governing permissions and
#	limitations under the License.
#

include /usr/local/share/luggage/luggage.make

TITLE=ipfw-firewall
REVERSE_DOMAIN=com.github.hjuutilainen
PAYLOAD=\
	pack-Library-LaunchDaemons-com.github.hjuutilainen.ipfw.plist\
	pack-private-etc-ipfw-ipfw-defaultrules.conf\
	pack-usr-local-bin-ipfw-control.sh\
	pack-usr-local-bin-ipfw-restart.sh\
	pack-script-postflight\
	pack-script-preflight

modify_packageroot:
	# Create a customrules directory
	@sudo mkdir -p ${WORK_D}/private/etc/ipfw/customrules
	@sudo chown root:wheel ${WORK_D}/private/etc/ipfw/customrules
	@sudo chmod 755 ${WORK_D}/private/etc/ipfw/customrules
	# Clear extended attributes
	@sudo xattr -c ${WORK_D}/private/etc/ipfw/ipfw-defaultrules.conf
	@sudo xattr -c ${WORK_D}/usr/local/bin/ipfw-control.sh
	@sudo xattr -c ${WORK_D}/usr/local/bin/ipfw-restart.sh
	@sudo xattr -c ${WORK_D}/Library/LaunchDaemons/com.github.hjuutilainen.ipfw.plist

prep-private-etc-ipfw: l_private_etc
	@sudo mkdir -p ${WORK_D}/private/etc/ipfw
	@sudo chown root:wheel ${WORK_D}/private/etc/ipfw
	@sudo chmod 755 ${WORK_D}/private/etc/ipfw

pack-private-etc-ipfw-ipfw-defaultrules.conf: prep-private-etc-ipfw
	@sudo ${CP} ipfw-defaultrules.conf ${WORK_D}/private/etc/ipfw
	@sudo chown root:wheel ${WORK_D}/private/etc/ipfw/ipfw-defaultrules.conf
	@sudo chmod 644 ${WORK_D}/private/etc/ipfw/ipfw-defaultrules.conf

