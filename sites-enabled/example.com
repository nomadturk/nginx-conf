#Let's redirect www requests to non-www site.
server {
	# don't forget to tell on which port this server listens
	listen 80;
	listen [::]:80 ipv6only=on;

	# listen on the www host
	server_name www.example.com;
	
	# Preserve the port when redirects.
	port_in_redirect off;
	
	# The below config will redirect ALL subdomains to non-www site.
	# If you don't have any other subdomains, you may enable this instead of the above one.
	# server_name *.example.com;

	# and redirect to the non-www host (declared below)
	# do no forget to replace example.com 
	return 301 $scheme://example.com$request_uri;
}

server {
	listen	80 ;
	listen	[::]:80 ipv6only=on;
		# listen	80 deferred;			# for Linux, might improve performance by reducing some formalities.
		# listen	80 accept_filter=httpready;	# for FreeBSD
		# listen	[::]:80 ipv6only=on;		# For only IPv6
	
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
