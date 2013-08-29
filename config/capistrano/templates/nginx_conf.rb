upstream <%= socket_name %> {
  server unix:<%= dir_pids %>/unicorn.sock fail_timeout=0;
}

server{
  listen 80;
  server_name <%= site_name %> www.<%= site_name %>;
  root <%= current_path %>/public;
  
  location / {
    proxy_redirect off;
    proxy_set_header Host $http_host;
    proxy_pass http://<%= socket_name %>;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; 
  }

  # serve static content directly
  location ~* \.(ico|jpg|gif|png|swf|html|js|css)$ {
    if (-f $request_filename) {
      expires max;
      #gzip_static on;
      #add_header Cache-Control public;
      break;
    }
  }
}