#!/bin/bash
# Let's Encrypt 证书申请 + Nginx HTTPS 配置脚本
# 域名: cqlrh.cn
# 博客目录: /home/ubuntu/my-blog

set -e

DOMAIN="cqlrh.cn"
WEBROOT="/home/ubuntu/my-blog"
NGINX_CONF="/etc/nginx/sites-enabled/default"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== 1. 安装 certbot ===${NC}"
sudo apt-get update -qq
sudo apt-get install -y -qq certbot python3-certbot-nginx

echo -e "${YELLOW}=== 2. 更新 Nginx 配置，添加域名 ===${NC}"
sudo tee "$NGINX_CONF" > /dev/null << 'NGINX_EOF'
server {
    listen 80;
    server_name cqlrh.cn www.cqlrh.cn;

    root /home/ubuntu/my-blog;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location /assets/ {
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    gzip on;
    gzip_types text/html text/css application/javascript image/svg+xml;
    gzip_min_length 256;
}
NGINX_EOF

sudo nginx -t && sudo nginx -s reload

echo -e "${YELLOW}=== 3. 申请 Let's Encrypt 证书 ===${NC}"
sudo certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" \
    --non-interactive \
    --agree-tos \
    --email "admin@${DOMAIN}" \
    --redirect

echo -e "${YELLOW}=== 4. 验证自动续签 ===${NC}"
sudo certbot renew --dry-run

echo -e "${GREEN}=== 完成！===${NC}"
echo -e "访问地址: ${GREEN}https://${DOMAIN}${NC}"
echo -e "证书会自动续签 (systemd timer 已启用)"