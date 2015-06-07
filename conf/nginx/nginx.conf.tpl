worker_processes  auto;

error_log  /var/log/nginx/error.log;

events {
  worker_connections  1024;
}

http {
  server_tokens off;
  include       mime.types;
  default_type  application/octet-stream;

  client_max_body_size 64M;

  log_format  main  '$http_x_forwarded_for - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

  access_log  /var/log/nginx/access.log  main;

  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  
  gzip  on;
  gzip_http_version 1.1;
  gzip_vary on;
  gzip_comp_level 5;
  gzip_proxied any;
  gzip_types text/plain text/html text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript application/javascript text/x-js;
  gzip_buffers 16 8k;
  gzip_disable "msie6";
  gzip_min_length 256;

  keepalive_timeout  8;
  
  # Upstream to abstract backend connection(s) for php
  upstream php {
    server 127.0.0.1:9000;
  }

  set_real_ip_from 10.0.0.0/8;
  real_ip_header X-Forwarded-For;
  real_ip_recursive on;
  
  server {
  
    server_name __DOMAIN;
    
    include /etc/nginx/aliases.conf;
   
    root /var/www/webroot/ROOT;

    index index.php;
    
    location = /favicon.ico {
      log_not_found off;
      access_log off;
    }

    location = /robots.txt {
      allow all;
      log_not_found off;
      access_log off;
    }

    location / {
      try_files $uri $uri/ /index.php?$args;
    }

    # to have w3-total-cache minify working
    location ~ ^/wp-content/cache/minify/[^/]+/(.*)$ {
      try_files $uri /wp-content/plugins/w3-total-cache/pub/minify.php?file=$1;
    }

    location ~ \.php$ {
      include fastcgi.conf;
      fastcgi_intercept_errors on;
      fastcgi_pass php;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
      expires max;
      log_not_found off;
    }
  }
}
