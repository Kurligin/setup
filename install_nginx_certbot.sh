#!/bin/bash
set -e

DOMAIN=$1
EMAIL=$2

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
  echo "❌ Использование: $0 <домен> <email>"
  echo "Пример: sudo ./install_nginx_certbot.sh example.com admin@example.com"
  exit 1
fi

echo "=== Обновление пакетов ==="
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl software-properties-common lsb-release

echo "=== Установка Nginx (официальный репозиторий Ubuntu) ==="
sudo apt-get install -y nginx

echo "=== Включение и запуск Nginx ==="
sudo systemctl enable nginx
sudo systemctl start nginx

echo "=== Установка Certbot (Let's Encrypt) ==="
sudo apt-get install -y certbot python3-certbot-nginx

echo "=== Проверка установки Certbot ==="
certbot --version

echo "=== Настройка брандмауэра (UFW) ==="
if command -v ufw >/dev/null 2>&1; then
  sudo ufw allow 'Nginx Full'
  sudo ufw delete allow 'Nginx HTTP' || true
  echo "✅ UFW настроен для HTTPS"
else
  echo "⚠️ UFW не установлен — пропуск настройки firewall"
fi

echo "=== Создание Nginx-конфига для $DOMAIN ==="
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN.conf"

sudo tee $NGINX_CONF > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN};

    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name ${DOMAIN};

    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    access_log /var/log/nginx/${DOMAIN}_access.log;
    error_log /var/log/nginx/${DOMAIN}_error.log;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_read_timeout 300;
        proxy_connect_timeout 60;
        proxy_send_timeout 300;
    }

    # (опционально) Сжатие ответов
    gzip on;
    gzip_types application/json text/plain application/javascript text/css;
    gzip_min_length 256;
}
EOF

echo "=== Активация конфига $DOMAIN ==="
sudo ln -sf /etc/nginx/sites-available/$DOMAIN.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

echo "=== Проверка DNS перед выпуском сертификата ==="
if ! ping -c 1 -W 2 "$DOMAIN" >/dev/null 2>&1; then
  echo "⚠️ Домен $DOMAIN не резолвится. Проверь DNS-запись (A/AAAA) перед запуском Certbot."
  exit 1
fi

echo "=== Выпуск и настройка SSL-сертификата для $DOMAIN ==="
sudo certbot --nginx -d "$DOMAIN" -m "$EMAIL" --agree-tos --redirect --non-interactive

echo "=== Добавление alias для проверки SSL ==="
if ! grep -q "alias sslcheck='sudo certbot certificates'" ~/.bashrc; then
  echo "alias sslcheck='sudo certbot certificates'" >> ~/.bashrc
fi
source ~/.bashrc

echo "=== Проверка автоматического обновления сертификата ==="
if systemctl list-timers | grep -q certbot; then
  echo "✅ Автообновление SSL уже включено"
else
  echo "⚙️ Включаю автообновление SSL..."
  sudo systemctl enable certbot.timer
fi

echo "=== Проверка установленных версий ==="
nginx -v
certbot --version

echo "✅ Установка завершена!"
echo "Домен: $DOMAIN"
echo "Email: $EMAIL"
echo "Nginx конфиг: /etc/nginx/sites-available/$DOMAIN.conf"
echo "Теперь твой API доступен по HTTPS через прокси на http://127.0.0.1:8000"```
