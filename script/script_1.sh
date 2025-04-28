#!/bin/bash
echo "Wait for 15 seconds"
sleep 15
sudo yum update -y
sudo amazon-linux-extras install nginx1 -y
sudo amazon-linux-extras enable nginx1

# Create self-signed certificate

sudo mkdir -p /etc/nginx/certs


sudo tee /etc/nginx/certs/tamvo.crt > /dev/null << 'EOF'
-----BEGIN CERTIFICATE-----
MIIB9jCCAXygAwIBAgIQTbNXNl5k8wPhfehpGbGXqjAKBggqhkjOPQQDAzBDMSow
KAYDVQQKEyFTdGFyY2FtcCBCYXRjaCAxMCwgR3JvdXAgU2VjdXJpdHkxFTATBgNV
BAMTDGhleXRhbXZvLmNvbTAeFw0yNTA0MjMwMjI2MjZaFw0yNTA0MjMxNDI2MjZa
MEMxKjAoBgNVBAoTIVN0YXJjYW1wIEJhdGNoIDEwLCBHcm91cCBTZWN1cml0eTEV
MBMGA1UEAxMMaGV5dGFtdm8uY29tMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAELPQo
g12br+n8B6poq2xe+G5D2bR4XwzmNS9xl8r/vYjRhSsx/0CtS6+ndAEjWP//Pufw
sPuMaqhM3R8yo2j8Xk1z/19mBu/z3ezQvtwRswN/EBHLiHwq6KAv2cYWKke8ozUw
MzAOBgNVHQ8BAf8EBAMCBaAwEwYDVR0lBAwwCgYIKwYBBQUHAwEwDAYDVR0TAQH/
BAIwADAKBggqhkjOPQQDAwNoADBlAjAW/j2SLfZdny3n6qonduTQAbH6uN4tGq7i
dJ0PAkgRa94j3lq/s8nAfMkYBWE51yICMQD9rgpDnlc7CNWGOcs/CrkYU7yo/rrI
B1VIPJzPOYIQZcwfRlTwlFNN3Q5Q+O7dB24=
-----END CERTIFICATE-----
EOF

sudo chmod 644 /etc/nginx/certs/tamvo.crt

sudo tee /etc/nginx/certs/tamvo.key > /dev/null << 'EOF'
-----BEGIN EC PRIVATE KEY-----
MIGkAgEBBDDY+8aWSkerS0OtKw6/EKtwLje6KqSYnX0ahy+cBG1HZtksa1q5DYF7
aaFi5LhsCyagBwYFK4EEACKhZANiAAQs9CiDXZuv6fwHqmirbF74bkPZtHhfDOY1
L3GXyv+9iNGFKzH/QK1Lr6d0ASNY//8+5/Cw+4xqqEzdHzKjaPxeTXP/X2YG7/Pd
7NC+3BGzA38QEcuIfCrooC/ZxhYqR7w=
-----END EC PRIVATE KEY-----
EOF

sudo chmod 644 /etc/nginx/certs/tamvo.key
# Config Nginx
sudo rm /etc/nginx/nginx.conf
sudo tee /etc/nginx/nginx.conf > /dev/null << 'EOF'

worker_processes  1;
events {
    worker_connections  1024;
}


http {
    include       mime.types;
    
    default_type  application/octet-stream;
    #

   
    sendfile        on;
    keepalive_timeout  65;
    
    server {
        listen       80;

        
        server_name  localhost;
        
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
        return 301 https://$host$request_uri;

    }
 
    # HTTPS server
    server {
        listen       443 ssl;
        listen       [::]:443 ssl;
        http2        on;
        server_name  _;
        root         /usr/share/nginx/html;

        ssl_certificate "/etc/nginx/certs/tamvo.crt";
        ssl_certificate_key "/etc/nginx/certs/tamvo.key";
        ssl_session_cache shared:SSL:1m;
        ssl_session_timeout  10m;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;

        # Load configuration files for the default server block.
        location / {
            #The location setting lets you configure how nginx responds to requests for resources within the server.
            root   html;
            index  index.html index.htm;
        }

        error_page 404 /404.html;
        location = /404.html {
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
        }
    }

}
EOF

# Create Private key
# sudo openssl genpkey -algorithm RSA -out tamvo.key -pkeyopt rsa_keygen_bits:2048 

# Create Self-signed cert request (CSR)
# sudo openssl req -new -key  tamvo.key -out  tamvo.csr -config /etc/nginx/certs/openssl-san.cnf

# Generate self-signed cert
# sudo openssl x509 -req -in tamvo.csr -signkey tamvo.key -out tamvo.crt -days 365 -extfile /etc/nginx/certs/openssl-san.cnf -extensions req_ext

# sudo cp tamvo.key /etc/nginx/certs/tamvo.key
# sudo cp tamvo.crt /etc/nginx/certs/tamvo.crt