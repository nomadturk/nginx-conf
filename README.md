nginx-conf
==========
# General purpose Nginx Configuration Template

## Nginx Template
Here lies my personal Nginx template for a mixed setup.
I'm trying to make this nginx configured for general use; whether it's wordpress or static html or whatever.
My aim is to enable caching, SEO friendly URL's, Cloudflare support, adding h5bp, ngx_pagespeed optimizations etc. Thus trying to create a copy/paste style nginx template.


It also uses https://github.com/h5bp/server-configs-nginx and a compilation of many tweaks.

### Requirements

Nginx 1.6 and above.
nginx-extras or your own compilation with the following:
* ngx_pagespeed (comes with nginx extras)
* ngx_http_gunzip


### What to do?
* Create cache and log folders
# Change ownership of the folders.


You can run the below bash script to create and chmod all these folders.
```
for dir in /var/cache/nginx/  /var/cache/nginx/client /var/cache/nginx/scgi /var/cache/nginx/uwsgi /var/cache/nginx/fastcgi /var/cache/nginx/proxy /var/ngx_pagespeed_cache /var/log/nginx /var/log/pagespeed /var/ngx_pagespeed_cache /var/log/pagespeed
do
if [ ! -d $dir ]; then
	mkdir -p $dir
	chown -R  www-data:www-data $dir
else
	chown -R  www-data:www-data $dir
fi
done
```
