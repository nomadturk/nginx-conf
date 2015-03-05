nginx-conf
==========
# General purpose Nginx Configuration Template

## Nginx Template
Here lies my personal Nginx template for a mixed setup.
I'm trying to make this nginx configured for general use; whether it's wordpress or static html or whatever.
My aim is to enable caching, SEO friendly URL's, Cloudflare support, adding h5bp, ngx_pagespeed optimizations etc. Thus trying to create a copy/paste style nginx template.


It also uses https://github.com/h5bp/server-configs-nginx and a compilation of many tweaks.




### What to do?
Some features come disabled by default. This is due to having different systems and different versions of nginx.
This is an all purpose nginx template so for the sake of compatibility some settings are disabled.

* Pagespeed settings: 1- Enable by uncommenting from within nginx.conf. Be sure to add your domains.  2- Enable pagespeed from within Example.com

* Gunzip settings: In the example.com file uncomment it if you need it.

* SPDY: For https sites, SPDY is a good addition but unfortunately you need nginx 1.6+ and it doesn't exist in some repos. So you have to enable it by adding "spdy" to the listen directive.
