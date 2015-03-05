#Let's redirect www requests to non-www site.
server {
  # don't forget to tell on which port this server listens
  listen 443 ssl spdy;
  listen [::]:443 ssl spdy;

  # listen on the www host
  server_name www.example.com;
  
  # The below config will redirect ALL subdomains to non-www site.
  # If you don't have any other subdomains, you may enable this instead of the above one.
  # server_name *.example.com;

  # and redirect to the non-www host (declared below)
  # do no forget to replace example.com 
  return 301 $scheme://example.com$request_uri;
}

server {
  listen 443 deferred ssl spdy;
  listen [::]:443 ssl spdy;
  
  ssl on;
  ssl_certificate_key /etc/ssl/cert/example.com.pem;
  ssl_certificate /etc/ssl/cert/ca-bundle.pem;

  # ssl_ciphers 'AES128+EECDH:AES128+EDH:!aNULL';
  # Backward compatible ciphers
  ssl_ciphers "ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4";

  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_session_cache shared:SSL:10m;
  ssl_session_timeout 20m;
  keepalive_timeout   70;
  
  # Buffer size of 1400 bytes fits in one MTU.
  # nginx 1.5.9+ ONLY
  ssl_buffer_size 1400;

  ssl_stapling on; # Requires nginx >= 1.3.7
  ssl_stapling_verify on; # Requires nginx => 1.3.7
  resolver 8.8.4.4 8.8.8.8 valid=300s;
  resolver_timeout 10s;

  ssl_prefer_server_ciphers on;
  ssl_dhparam /etc/ssl/certs/dhparam.pem;
  # cd /etc/ssl/certs
  # openssl dhparam -out dhparam.pem 4096

  add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
  add_header X-Frame-Options DENY;
  add_header X-Content-Type-Options nosniff;
  
  # SPDY header compression (0 for none, 9 for slow/heavy compression). Preferred is 6.
  # BUT: header compression is flawed and vulnerable in SPDY versions 1 - 3.
  # Disable with 0, until using a version of nginx with SPDY 4.
  spdy_headers_comp 1;
  
  ###
  ###
  ### Below here is the same with non-ssl server settings..
  ###
  ###
	
	# our primary server name is the first, aliases simply come after it. you can also include wildcards like *.example.com
	server_name	example.com;
		
	# Path for the website
	root	/var/www/;
	
	#access_log	logs/host.access.log	main;
	
	# http://nginx.com/resources/admin-guide/compression-and-decompression/
	gunzip on;
	
	index	index.php index.html index.htm;

	server_name_in_redirect off;
		
	# Remove auto listing of directories. 
	autoindex off;
	
	# You can enable this for prettier directory listings if you enable autoindex.
	fancyindex off;
	
	# Set default charset as unicode.
	charset utf-8;
	
	###############################################
	location / {
		# the magic. this is the equivalent of all those lines you use for mod_rewrite in Apache
		# if the request is for "/foo", we'll first try it as a file. then as a directory. and finally
		# we'll assume its some sort of "clean" url and hand it to index.php so our CMS can work with it
		try_files $uri $uri/ /index.php$is_args$args;
	
		#Some software doesn't even need the query string, and can read from REQUEST_URI (WordPress supports this, for example)
		# http://docs.ngx.cc/en/latest/topics/tutorials/config_pitfalls.html
		#try_files $uri $uri/ /index.php?q=$uri&$args;
	}
	###############################################
	
	# Let's Include Cache settings
	include /etc/nginx/nomad-conf/cachestatic.add;
	
	# Preserve the port when redirects.
	port_in_redirect off;
	 
	# Wordpress settings for /wordpress folder
	include /etc/nginx/nomad-conf/wordpress.add;
	 
	# include /etc/nginx/security;
	
	# Include the basic h5bp config set
	include /etc/nginx/h5bp/basic.conf;
	
	# Let's Include PageSpeed
	include /etc/nginx/nomad-conf/pagespeed.add;

	# PHP Settings
	include /etc/nginx/nomad-conf/fastcgi.add;
	
	# Get real IP from Varnish and Cloudflare for Logging
	include /etc/nginx/nomad-conf/realip.add;
	
	# Redirect server error pages to the static page /50x.html
	include /etc/nginx/nomad-conf/serverror.add;
	 
	# Deny access to htaccess files
	include /etc/nginx/nomad-conf/deny-htaccess.add;
		
	# Varnish probe 
	include /etc/nginx/nomad-conf/probe.add;
	
	# Let us not log favicon and robots and whatever
	include /etc/nginx/nomad-conf/donotlog.add;
	
	# Create an /nginx-status page. 
	include /etc/nginx/nomad-conf/status-stub.add;
}
