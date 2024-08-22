server {
    listen 10998;                        
    server_name localhost;

    location / {
        index index.html;
        proxy_set_header Host $http_host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_pass http://${proxy_pass};    
    }

    error_page 400 404 413 502 504 /50x.html;
}
