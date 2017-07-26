# vkucukcakar/ngx-cf-ip

ngx-cf-ip as Docker image. (ngx-cf-ip: Cloudflare IP updater for Nginx ngx_http_realip_module)

* Downloads Cloudflare IPv4 and IPv6 lists and merge
* IP address and list validation just in case
* Creates a new nginx configuration file using set_real_ip_from directives and IP addresses
* Configuration file ready to be included (/cloudflare/cf.conf)
* Reloads Nginx without restarting container

## Supported tags

* alpine, latest

## Environment variables supported

* SCHEDULE=["15 3 * * *"]
	Cron schedule. Do not set to assign default value, daily/03:15.
* SERVER_CONTAINER_NAME=[server-proxy]
	Container name of Nginx server to be reloaded. If set, /var/run/docker.sock must be mounted.
* RELOAD_COMMAND=['echo -e \"POST /containers/server-proxy/kill?signal=HUP HTTP/1.0\r\n\" | nc -U /var/run/docker.sock']
	Override default reload command. The default reload command sends Nginx container a HUP signal which makes Nginx 
	reload configuration files without restarting container itself.	There is no need to override default reload 
	command if you use official Nginx images or any other Nginx image that use Nginx master process as PID 1. 
	The above example is already the default reload command and just given to demonstrate quoting.
	In other words, RELOAD_COMMAND should not be set while using official Nginx image or any compatible image.
* EXTRA_PARAMETERS=['--timeout==60']
	Extra parameters for ngx-cf-ip, except "-u, --update, -o, --output, -r, --reload" since they are hardcoded and
	handled by image.

## Example

	$ docker run --name my-cf-ip-updater -v /my/location/cloudflare:/cloudflare -v /var/run/docker.sock:/var/run/docker.sock -e SERVER_CONTAINER_NAME=server-proxy -d vkucukcakar/ngx-cf-ip

## Caveats

* Docker socket must me mounted to /var/run/docker.sock for default reload command to work.
* Output directory /cloudflare should be mounted and the created output file /cloudflare/cf.conf should be included by your (proxy) Nginx server.
