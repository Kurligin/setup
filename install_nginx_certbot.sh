#!/bin/bash
set -e

echo "=== Обновление пакетов ==="
sudo apt-get update
sudo apt-get install -y ca-certificates curl software-properties-common lsb-release

echo "=== Установка Nginx (официальный репозиторий Ubuntu) ==="
sudo apt-get update
sudo apt-get install -y nginx

echo "=== Включение и запуск Nginx ==="
sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl status nginx --no-pager || true

echo "=== Установка Certbot (Let's Encrypt) ==="
sudo apt-get install -y certbot python3-certbot-nginx

echo "=== Проверка установки Certbot ==="
certbot --version

echo "=== Настройка брандмауэра (UFW) ==="
if command -v ufw >/dev/null 2>&1; then
  sudo ufw allow 'Nginx Full'
  sudo ufw delete allow 'Nginx HTTP' || true
  echo "UFW настроен для HTTPS"
else
  echo "UFW не установлен — пропуск настройки firewall"
fi

echo "=== Установка alias для проверки SSL ==="
if ! grep -q "alias sslcheck='sudo certbot certificates'" ~/.bashrc; then
  echo "alias sslcheck='sudo certbot certificates'" >> ~/.bashrc
fi
source ~/.bashrc

echo "=== Проверка версий ==="
nginx -v
certbot --version

echo "=== Установка завершена! ==="
echo "Теперь можешь добавить свой конфиг в /etc/nginx/sites-available/"
echo "и затем выполнить certbot --nginx -d <домен> -m <email> --agree-tos --redirect"