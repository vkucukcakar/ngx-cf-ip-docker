#!/bin/bash

###
# vkucukcakar/ngx-cf-ip
# ngx-cf-ip as Docker image. (ngx-cf-ip: Cloudflare IP updater for Nginx ngx_http_realip_module)
# Copyright (c) 2017 Volkan Kucukcakar
# 
# This file is part of vkucukcakar/ngx-cf-ip.
# 
# vkucukcakar/ngx-cf-ip is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# vkucukcakar/ngx-cf-ip is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
# This copyright notice and license must be retained in all files and derivative works.
###


# Remove previous ngx-cf-ip pid file if survived from an unexpected container crash
rm /var/run/ngx-cf-ip.pid >/dev/null 2>&1

# Check if the server container to be reloaded is set
if [ "$SERVER_CONTAINER_NAME" ]; then
	# Check if docker.sock is mounted
	if [ ! -e /var/run/docker.sock ]; then
		echo "Error: /var/run/docker.sock not mounted which is required to reload Nginx when SERVER_CONTAINER_NAME specified."
		exit 1
	fi
	echo "Nginx will be automatically reloaded when Cloudflare IP list updated."
	# Set reload command
	if [ "$RELOAD_COMMAND" ]; then
		_RELOAD="-r --command=\"$RELOAD_COMMAND\" "
		echo "Custom reload command will be used."
	else
		echo "Default reload command will be used."
		# Sending HUP signal to Nginx container makes Nginx to reload configurations without restarting container (when official or any other Nginx image that using Nginx master process as PID 1)
		_RELOAD="-r --command=\"echo -e \\\"POST /containers/${SERVER_CONTAINER_NAME}/kill?signal=HUP HTTP/1.0\r\n\\\" | nc -U /var/run/docker.sock\" "
	fi
else
	echo "SERVER_CONTAINER_NAME not set. Nginx will not be automatically reloaded when Cloudflare IP list updated."
	_RELOAD=""
fi
	echo "Output Nginx Cloudflare configuration file will be saved to /cloudflare/cf.conf"
	# Set schedule to daily if empty
	[ -z "$SCHEDULE" ] && export SCHEDULE="15 3 * * *"
	# Restore crontab
	cp /ngx-cf-ip/crontabs/root /etc/crontabs/
	# Do not echo all with -e to prevent the need for extra quoting text in parameters
	echo -e "\n" >>/etc/crontabs/root
	# Add ngx-cf-ip to crontab
	echo "$SCHEDULE /usr/local/bin/ngx-cf-ip.php -u --output=\"/cloudflare/cf.conf\" ${_RELOAD}${EXTRA_PARAMETERS} >>/var/log/cron.log 2>>/var/log/cron-error.log" >>/etc/crontabs/root
	# Initially run ngx-cf-ip (Note: Without eval, quotes in variable will make command failed. It is related to the behavior of bash and a little complicated...)
	eval "/usr/local/bin/ngx-cf-ip.php -u --output=\"/cloudflare/cf.conf\" ${_RELOAD}${EXTRA_PARAMETERS} >>/var/log/cron.log 2>>/var/log/cron-error.log"

# Execute another entrypoint or CMD if there is one
if [[ "$@" ]]; then
	echo "Executing $@"
	$@
	EXITCODE=$?
	if [[ $EXITCODE > 0 ]]; then 
		echo "Error: $@ finished with exit code: $EXITCODE"
		exit $EXITCODE; 
	fi
fi
