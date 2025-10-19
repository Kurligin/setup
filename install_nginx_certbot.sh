#!/bin/bash
set -e

echo "=== Обновление пакетов ==="
sudo apt-get update
sudo apt-get install -y ca-certificates curl software-properties-common lsb-release

echo "=== Установка Nginx (официальный репозиторий Ubuntu) ==="
sudo apt-get update
sudo apt-get install -y nginx

echo "=== Проверка статуса Nginx ==="
sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl status nginx --no-pager

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

echo "=== Выпуск SSL-сертификата Let's Encrypt ==="
read -p "Введите ваш домен (например, example.com): " DOMAIN
read -p "Введите ваш email для уведомлений Let's Encrypt: " EMAIL

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
  echo "Ошибка: домен и email обязательны!"
  exit 1
fi

sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect

echo "=== Проверка автообновления сертификатов ==="
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
sudo systemctl status certbot.timer --no-pager

echo "=== Тест обновления сертификата ==="
sudo certbot renew --dry-run

echo "=== Проверка конфигурации Nginx ==="
sudo nginx -t

echo "=== Перезапуск Nginx ==="
sudo systemctl reload nginx

echo "=== Установка alias для проверки SSL ==="
if ! grep -q "alias sslcheck='sudo certbot certificates'" ~/.bashrc; then
  echo "alias sslcheck='sudo certbot certificates'" >> ~/.bashrc
fi
source ~/.bashrc

echo "=== Проверка версий ==="
nginx -v
certbot --version

echo "=== Установка и настройка завершены! ==="
echo "Ваш сайт доступен по HTTPS: https://$DOMAIN"