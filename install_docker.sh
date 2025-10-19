#!/bin/bash
set -e

echo "=== Обновление пакетов ==="
sudo apt-get update
sudo apt-get install -y ca-certificates curl

echo "=== Добавление ключа Docker ==="
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "=== Добавление репозитория Docker ==="
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "=== Установка Docker и плагинов ==="
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "=== Установка lazydocker ==="
LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
curl -Lo lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz"

mkdir lazydocker-temp
tar xf lazydocker.tar.gz -C lazydocker-temp
sudo mv lazydocker-temp/lazydocker /usr/local/bin
rm -rf lazydocker.tar.gz lazydocker-temp

echo "=== Настройка alias для lazydocker ==="
if ! grep -q "alias ld='lazydocker'" ~/.bashrc; then
  echo "alias ld='lazydocker'" >> ~/.bashrc
fi
source ~/.bashrc

echo "=== Проверка версий ==="
docker --version
docker compose version
lazydocker --version

echo "=== Установка завершена! ==="