#!/bin/bash

# ======================
# Enhanced Docker Installation Script
# ======================

set -e  # Exit on any error

# ======================
# Цвета для вывода
# ======================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ======================
# ФУНКЦИИ
# ======================

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        log_success "$1 установлен успешно"
        return 0
    else
        log_error "$1 не найден"
        return 1
    fi
}

# ======================
# ПРОВЕРКИ
# ======================

log_info "Проверяем права доступа..."
if [[ $EUID -ne 0 ]]; then
   log_error "Этот скрипт должен быть запущен от имени root (используйте sudo)"
   exit 1
fi

log_info "Проверяем операционную систему..."
if [[ ! -f /etc/os-release ]]; then
    log_error "Не удалось определить операционную систему"
    exit 1
fi

# Определяем текущего пользователя (не root)
CURRENT_USER=${SUDO_USER:-$(logname 2>/dev/null || echo $USER)}
log_info "Текущий пользователь: $CURRENT_USER"

# ======================
# ОБНОВЛЕНИЕ СИСТЕМЫ
# ======================

log_info "Обновляем систему..."
export DEBIAN_FRONTEND=noninteractive

apt-get update -y || { log_error "Не удалось обновить список пакетов"; exit 1; }
apt-get upgrade -y || { log_error "Не удалось обновить систему"; exit 1; }

log_info "Устанавливаем базовые зависимости..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    wget \
    gnupg \
    lsb-release \
    software-properties-common || { log_error "Не удалось установить базовые зависимости"; exit 1; }

# ======================
# УСТАНОВКА DOCKER
# ======================

log_info "Удаляем старые версии Docker..."
apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

log_info "Устанавливаем Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh || { log_error "Не удалось скачать установщик Docker"; exit 1; }
sh get-docker.sh || { log_error "Не удалось установить Docker"; exit 1; }
rm get-docker.sh

log_info "Настраиваем Docker service..."
systemctl enable docker || { log_error "Не удалось включить Docker service"; exit 1; }
systemctl start docker || { log_error "Не удалось запустить Docker service"; exit 1; }

# Проверяем установку Docker
sleep 2
if ! check_command docker; then
    log_error "Docker не был установлен корректно"
    exit 1
fi

# ======================
# УСТАНОВКА DOCKER COMPOSE PLUGIN
# ======================

log_info "Устанавливаем Docker Compose plugin..."

ARCH=$(uname -m)
PLUGIN_DIR=/usr/libexec/docker/cli-plugins
mkdir -p "$PLUGIN_DIR"

log_info "Архитектура системы: $ARCH"

COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
log_info "Последняя версия Docker Compose: $COMPOSE_VERSION"

if [ "$ARCH" = "x86_64" ]; then
    COMPOSE_URL="https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-linux-x86_64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    COMPOSE_URL="https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-linux-aarch64"
else
    log_error "Архитектура $ARCH не поддерживается"
    exit 1
fi

curl -L "$COMPOSE_URL" -o "$PLUGIN_DIR/docker-compose" || { log_error "Не удалось скачать Docker Compose"; exit 1; }
chmod +x "$PLUGIN_DIR/docker-compose"

# Добавляем симлинк для совместимости
ln -sf "$PLUGIN_DIR/docker-compose" /usr/local/bin/docker-compose

# Проверяем установку Docker Compose
sleep 2
if docker compose version >/dev/null 2>&1; then
    log_success "Docker Compose установлен успешно"
else
    log_error "Docker Compose не был установлен корректно"
    exit 1
fi

# ======================
# УСТАНОВКА УТИЛИТ
# ======================

log_info "Устанавливаем полезные утилиты..."
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
    fail2ban \
    ufw \
    rsync \
    build-essential || { log_error "Не удалось установить некоторые утилиты"; exit 1; }

# ======================
# НАСТРОЙКА ПОЛЬЗОВАТЕЛЯ
# ======================

if [ -n "$CURRENT_USER" ] && [ "$CURRENT_USER" != "root" ]; then
    log_info "Добавляем пользователя $CURRENT_USER в группу docker..."
    usermod -aG docker "$CURRENT_USER" || { log_warning "Не удалось добавить пользователя в группу docker"; }
    log_success "Пользователь $CURRENT_USER добавлен в группу docker"
fi

# ======================
# ОПТИМИЗАЦИЯ СИСТЕМЫ
# ======================

log_info "Оптимизируем систему..."

# Настройка vm.max_map_count для Elasticsearch и подобных приложений
sysctl -w vm.max_map_count=262144
if ! grep -q "vm.max_map_count" /etc/sysctl.conf; then
    echo "vm.max_map_count=262144" >> /etc/sysctl.conf
    log_success "Настроен vm.max_map_count"
fi

# Настройка файрвола
log_info "Настраиваем UFW..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 22/tcp
ufw --force enable
log_success "UFW настроен и включен"

# Чистим систему
log_info "Очищаем систему..."
apt-get autoremove -y
apt-get autoclean
screen -wipe >/dev/null 2>&1 || true

# ======================
# ДОПОЛНИТЕЛЬНЫЕ НАСТРОЙКИ
# ======================

log_info "Применяем дополнительные настройки..."

# Настройка логирования Docker
cat > /etc/docker/daemon.json << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

systemctl restart docker
log_success "Docker daemon настроен"

# ======================
# ПРОВЕРКА УСТАНОВКИ
# ======================

log_info "Проверяем установку..."

echo ""
log_success "=== ПРОВЕРКА ВЕРСИЙ ==="
docker --version
docker compose version

echo ""
log_success "=== ИНФОРМАЦИЯ О СИСТЕМЕ ==="
echo "Операционная система: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Архитектура: $(uname -m)"
echo "Ядро: $(uname -r)"

# Тест Docker
log_info "Тестируем Docker..."
if docker run --rm hello-world >/dev/null 2>&1; then
    log_success "Docker работает корректно"
else
    log_warning "Возможны проблемы с Docker, проверьте настройки"
fi

# ======================
# ФИНАЛЬНЫЕ ИНСТРУКЦИИ
# ======================

echo ""
log_success "🎉 УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО!"
echo ""
echo -e "${YELLOW}📋 ВАЖНЫЕ ИНСТРУКЦИИ:${NC}"

if [ -n "$CURRENT_USER" ] && [ "$CURRENT_USER" != "root" ]; then
    echo -e "   1. Для использования Docker без sudo выполните:"
    echo -e "      ${BLUE}newgrp docker${NC} или перезайдите в систему"
    echo ""
fi

echo -e "   2. Полезные команды:"
echo -e "      ${BLUE}docker --version${NC}                 - версия Docker"
echo -e "      ${BLUE}docker compose version${NC}           - версия Docker Compose"
echo -e "      ${BLUE}docker ps${NC}                        - список контейнеров"
echo -e "      ${BLUE}docker images${NC}                    - список образов"
echo -e "      ${BLUE}systemctl status docker${NC}          - статус Docker service"
echo ""

echo -e "   3. Настройка завершена для пользователя: ${GREEN}$CURRENT_USER${NC}"
echo -e "   4. Логи Docker: ${BLUE}journalctl -u docker${NC}"
echo ""

log_success "Система готова к работе с Docker!"
