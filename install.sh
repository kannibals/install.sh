#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# =====================
# 1. ОБНОВЛЕНИЕ СИСТЕМЫ
# =====================
echo -e "${YELLOW}🔹 Обновляем систему...${NC}"
apt-get update
apt-get upgrade -y
apt-get install -y apt-transport-https ca-certificates software-properties-common curl wget

# ==============
# 2. УСТАНОВКА DOCKER
# ==============
echo -e "${YELLOW}🔹 Устанавливаем Docker и Docker Compose...${NC}"

# Удаляем старые версии
apt-get remove -y docker docker-engine docker.io containerd runc

# Установка Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# Docker Compose v2
mkdir -p /usr/libexec/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/libexec/docker/cli-plugins/docker-compose
chmod +x /usr/libexec/docker/cli-plugins/docker-compose

# Настройка Docker
chmod 666 /var/run/docker.sock
systemctl enable docker
systemctl start docker

# ========================
# 3. ПОЛЕЗНЫЕ ИНСТРУМЕНТЫ
# ========================
echo -e "${YELLOW}🔹 Устанавливаем утилиты...${NC}"

# Базовые пакеты
apt-get install -y \
    htop \
    screen \
    tmux \
    ncdu \
    nnn \
    git \
    tree \
    jq \
    zip \
    unzip \
    net-tools \
    iputils-ping \
    traceroute \
    nano \
    vim \
    gnupg2 \
    sshpass \
    fail2ban \
    ufw

# =================
# 4. ОПТИМИЗАЦИЯ
# =================
echo -e "${YELLOW}🔹 Оптимизируем систему...${NC}"

# Увеличиваем лимиты для Docker
sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" >> /etc/sysctl.conf

# Настройка файрвола
ufw allow 22
ufw allow 80
ufw allow 443
ufw --force enable

# =============
# ЗАВЕРШЕНИЕ
# =============
echo -e "${GREEN}
✅ Готово! Система настроена.
➜ Проверьте версии:
  docker --version
  docker compose version
${NC}"

# Самоудаление (раскомментируйте если нужно)
# rm -- "$0"
