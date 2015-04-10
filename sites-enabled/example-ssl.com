#Let's redirect http and www requests to non-www site.
server {
  # don't forget to tell on which port this server listens
  listen 80;
  listen [::]:80 ipv6only on;
  
  listen 443 ssl spdy;
  listen [::]:443 ssl spdy;

  # listen on the www host
  server_name www.example.com;
 
  # and redirect to the non-www host (declared below)
  # do no forget to replace example.com 
  return 301 https://example.com$request_uri;
}

server {
  listen 443 ssl spdy;			#SPDY Requires nginx 1.6+
  listen [::]:443 ssl spdy;
  
 # Enable below with your certificates
 ssl on;
 ssl_certificate_key /etc/ssl/cert/example.com.key;		# Replace this with your certificate key
 ssl_certificate /etc/ssl/cert/example.com.bundle.crt 			# Replace it with your ca-bundle.pem;

  # ssl_ciphers 'AES128+EECDH:AES128+EDH:!aNULL';
  # Backward compatible ciphers
  ssl_ciphers "ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4";
  ssl_prefer_server_ciphers on;

  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_session_cache shared:SSL:50m;
  ssl_session_timeout 20m;
  keepalive_timeout   70;
  
  # Buffer size of 1400 bytes fits in one MTU.
  # nginx 1.5.9+ ONLY
  ssl_buffer_size 1400;

  ssl_stapling on; # Requires nginx >= 1.3.7
  ssl_stapling_verify on; # Requires nginx => 1.3.7
  resolver 8.8.4.4 8.8.8.8 valid=300s;
  resolver_timeout 10s;
#  ssl_stapling_file  /etc/ssl/domain.bundle.pem.ocsp;

  # For Diffie Hellman Key Exchange:
  ssl_dhparam /var/www/vhosts/cloud.golgeli.net/ssl/dhparam.pem;
  # cd /var/www/vhosts/cloud.golgeli.net/ssl/
  # openssl dhparam -out dhparam.pem 4096

  # let the browsers know that we only accept HTTPS
  # HSTS (ngx_http_headers_module is required) (15768000 seconds = 6 months)
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
	
	access_log	logs/host.access.log	main;
	error_log	logs/host.error.log	main;
	
	# Enable gunzip if you have gunzip module compiled with nginx.
	# http://nginx.com/resources/admin-guide/compression-and-decompression/
	# gunzip on;
	
	index	index.php index.html index.htm;

	server_name_in_redirect off;
		
	# Remove auto listing of directories. 
	autoindex off;
	
	# You can enable this for prettier directory listings if you enable autoindex. fancyindex module must be compiled with nginx.
	# fancyindex off;
	
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
	include nomad-conf/cachestatic.add;
	
	# Wordpress settings for /wordpress folder
	include nomad-conf/wordpress.add;
	 
	# Include the basic h5bp config set
	include h5bp/basic.conf;
	
	# Let's Include PageSpeed
#	include nomad-conf/pagespeed.add;

	# PHP Settings
	include nomad-conf/fastcgi.add;
	
	# Get real IP from Varnish and Cloudflare for Logging
	include nomad-conf/realip.add;
	
	# Redirect server error pages to the static page /50x.html
	include nomad-conf/serverror.add;
	 
	# Deny access to htaccess files
	include nomad-conf/deny-htaccess.add;
		
	# Varnish probe 
	include nomad-conf/probe.add;
	
	# Let us not log favicon and robots and whatever
	include nomad-conf/donotlog.add;
	
	# Create an /nginx-status page. 
	include nomad-conf/status-stub.add;
}
