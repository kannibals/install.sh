#!/bin/bash

# =============================================
# НАСТРОЙКА СИСТЕМЫ ПОСЛЕ УСТАНОВКИ ОБРАЗА
# =============================================

set -e # Выход при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Проверка на root
if [ "$(id -u)" -eq 0 ]; then
  echo -e "${RED}Ошибка: не запускайте скрипт от root! Используйте обычного пользователя с sudo.${NC}"
  exit 1
fi

# =====================
# 1. ОБНОВЛЕНИЕ СИСТЕМЫ
# =====================
echo -e "${YELLOW}🔹 Обновляем систему...${NC}"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y apt-transport-https ca-certificates software-properties-common curl wget

# ==============
# 2. УСТАНОВКА DOCKER
# ==============
echo -e "${YELLOW}🔹 Устанавливаем Docker и Docker Compose...${NC}"

# Удаляем старые версии
sudo apt-get remove -y docker docker-engine docker.io containerd runc

# Установка Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# Docker Compose v2
sudo mkdir -p /usr/libexec/docker/cli-plugins
sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/libexec/docker/cli-plugins/docker-compose
sudo chmod +x /usr/libexec/docker/cli-plugins/docker-compose

# Настройка прав
sudo usermod -aG docker $USER
sudo chmod 666 /var/run/docker.sock
sudo systemctl enable docker
sudo systemctl start docker

# ========================
# 3. ПОЛЕЗНЫЕ ИНСТРУМЕНТЫ
# ========================
echo -e "${YELLOW}🔹 Устанавливаем утилиты...${NC}"

# Базовые
sudo apt-get install -y \
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
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf

# Настройка файрвола
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable

# =================
# 5. ДОПОЛНИТЕЛЬНО
# =================
echo -e "${YELLOW}🔹 Дополнительные настройки...${NC}"

# Установка zsh (опционально)
sudo apt-get install -y zsh
if [ -f "$HOME/.zshrc" ]; then
  echo -e "${GREEN}Zsh уже настроен.${NC}"
else
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  chsh -s $(which zsh)
fi

# =============
# ЗАВЕРШЕНИЕ
# =============
echo -e "${GREEN}
✅ Готово! Система настроена.
➜ Перезайдите в систему для применения изменений прав Docker.
➜ Проверьте версии:
  docker --version
  docker compose version
${NC}"

# Самоудаление (раскомментируйте если нужно)
# rm -- "$0"
