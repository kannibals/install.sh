#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🔹 Обновляем систему...${NC}"
apt-get update && apt-get upgrade -y

# ======================
# УСТАНОВКА DOCKER CE И DOCKER COMPOSE V2
# ======================
echo -e "${YELLOW}🔹 Устанавливаем Docker CE и Docker Compose v2...${NC}"

# Установка зависимостей
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common

# Добавляем ключ Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Добавляем репозиторий Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Установка Docker CE
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Добавляем текущего пользователя в группу docker
sudo usermod -aG docker $USER
newgrp docker

# Включаем и запускаем Docker
sudo systemctl enable docker
sudo systemctl start docker

# Установка Docker Compose v2
ARCH=$(uname -m)
PLUGIN_DIR=/usr/libexec/docker/cli-plugins
sudo mkdir -p "$PLUGIN_DIR"

if [ "$ARCH" = "x86_64" ]; then
    sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o "$PLUGIN_DIR/docker-compose"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-aarch64 -o "$PLUGIN_DIR/docker-compose"
else
    echo -e "${RED}⚠️ Архитектура $ARCH не поддерживается, установите Compose вручную.${NC}"
fi

sudo chmod +x "$PLUGIN_DIR/docker-compose"

# ======================
# УТИЛИТЫ
# ======================
echo -e "${YELLOW}🔹 Устанавливаем утилиты...${NC}"
apt-get install -y \
htop screen tmux ncdu nnn git tree jq \
zip unzip net-tools iputils-ping traceroute \
nano vim fail2ban ufw lxterminal

# ======================
# ОПТИМИЗАЦИЯ
# ======================
echo -e "${YELLOW}🔹 Оптимизируем систему...${NC}"
sysctl -w vm.max_map_count=262144
grep -q "vm.max_map_count" /etc/sysctl.conf || echo "vm.max_map_count=262144" >> /etc/sysctl.conf

ufw allow 22/tcp
ufw --force enable

# Чистим dead screen-сессии
screen -wipe >/dev/null 2>&1

# Проверка версий
echo -e "${GREEN}✅ Docker и Docker Compose v2 установлены.${NC}"
docker --version
docker compose version
