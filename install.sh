#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🔹 Обновляем систему...${NC}"
apt-get update && apt-get upgrade -y
apt-get install -y apt-transport-https ca-certificates curl wget gnupg lsb-release software-properties-common

# ======================
# УСТАНОВКА DOCKER
# ======================
echo -e "${YELLOW}🔹 Устанавливаем Docker...${NC}"
apt-get install -y docker.io
systemctl enable docker
systemctl start docker

# ======================
# УСТАНОВКА DOCKER COMPOSE PLUGIN
# ======================
echo -e "${YELLOW}🔹 Устанавливаем Docker Compose plugin...${NC}"
mkdir -p /usr/libexec/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/libexec/docker/cli-plugins/docker-compose
chmod +x /usr/libexec/docker/cli-plugins/docker-compose

# ======================
# УТИЛИТЫ
# ======================
echo -e "${YELLOW}🔹 Устанавливаем утилиты...${NC}"
apt-get install -y \
htop screen tmux ncdu nnn git tree jq \
zip unzip net-tools iputils-ping traceroute \
nano vim fail2ban ufw

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

# ======================
# ФИНАЛ
# ======================
echo -e "${GREEN}
✅ Готово! Система настроена.
Проверка версий:
docker --version
docker compose version
${NC}"
