nginx-conf
==========
# General purpose Nginx Configuration Template

## Nginx Template
Here lies my personal Nginx template for a mixed setup.
I'm trying to make this nginx configured for general use; whether it's wordpress or static html or whatever.
My aim is to enable caching, SEO friendly URL's, Cloudflare support, adding h5bp, ngx_pagespeed optimizations etc. Thus trying to create a copy/paste style nginx template.


It also uses https://github.com/h5bp/server-configs-nginx and a compilation of many tweaks.




### Dealing with possible errors.
###### Error - Pagespeed
**You might run into errors if you don't have ngx_pagespeed module.**
* Solution: Manually disable pagespeed references or install pagespeed. If you are compiling your own nginx, make sure you have ngx_pagespeed added as a module in compile options.

##### Error - Gunzip
**You might run into errors if you don't have ngx_http_gunzip_filter_module**
* Solution: Either disable the directive or include https://github.com/catap/ngx_http_gunzip_filter_module to your compilation.
