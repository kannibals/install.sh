#!/bin/bash
set -Eeuo pipefail

# ======================
# ПЕРЕМЕННЫЕ И ФУНКЦИИ
# ======================
# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

need_sudo() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

# ======================
# ОБНОВЛЕНИЕ И ЗАВИСИМОСТИ
# ======================
echo -e "${YELLOW}🔹 Обновляем систему...${NC}"
need_sudo apt-get update && need_sudo apt-get upgrade -y
need_sudo apt-get autoremove -y

echo -e "${YELLOW}🔹 Устанавливаем зависимости...${NC}"
need_sudo apt-get install -y ca-certificates curl gnupg lsb-release software-properties-common

DEBIAN_FRONTEND=noninteractive need_sudo apt install iperf3 -y

# ======================
# СОЗДАНИЕ КАСТОМНЫХ СКРИПТОВ
# ======================
echo -e "${YELLOW}🔹 Создаем утилиты в /scripts...${NC}"
need_sudo mkdir -p /scripts

# Создаем файлы и пишем в них через sudo + tee
need_sudo tee /scripts/update > /dev/null << 'EOF'
#!/bin/bash
apt update
apt upgrade -y
EOF

need_sudo tee /scripts/clean > /dev/null << 'EOF'
#!/bin/bash
apt autoremove --purge -y && apt autoclean && apt clean
apt-get purge $(dpkg -l 'linux-image-*' | awk '/^ii/{print $2}' | grep -v $(uname -r) | head -n -1) -y
update-grub
journalctl --disk-usage
journalctl --vacuum-time=3d
docker system prune -a --volumes -f
truncate -s 0 /var/lib/docker/containers/*/*-json.log 2>/dev/null || true
EOF

need_sudo tee /scripts/speed > /dev/null << 'EOF'
#!/bin/bash
iperf3 -c speedtest.fra1.de.leaseweb.net -p 5202 -P8
EOF

need_sudo chmod +x /scripts/update /scripts/clean /scripts/speed

# Добавляем алиасы
grep -q "alias update=" ~/.bashrc || sed -i '/# some more ls aliases/a alias update="/scripts/update"' ~/.bashrc
grep -q "alias clean=" ~/.bashrc || sed -i '/# some more ls aliases/a alias clean="/scripts/clean"' ~/.bashrc
grep -q "alias speed=" ~/.bashrc || sed -i '/# some more ls aliases/a alias speed="/scripts/speed"' ~/.bashrc

# ======================
# УСТАНОВКА DOCKER И COMPOSE
# ======================
echo -e "${YELLOW}🔹 Настраиваем репозиторий Docker...${NC}"
need_sudo install -m 0755 -d /etc/apt/keyrings

if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | need_sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg
  need_sudo chmod a+r /etc/apt/keyrings/docker.gpg
fi

CODENAME="$(. /etc/os-release && printf '%s' "$VERSION_CODENAME")"
ARCH="$(dpkg --print-architecture)"
printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu %s stable\n' "$ARCH" "$CODENAME" \
  | need_sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

echo -e "${YELLOW}🔹 Устанавливаем Docker CE и Docker Compose Plugin...${NC}"
need_sudo apt-get update
need_sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

if command -v systemctl >/dev/null 2>&1; then
  need_sudo systemctl enable --now docker
fi

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  need_sudo usermod -aG docker "$USER" || true
  echo -e "${YELLOW}⚠️ Пользователь $USER добавлен в группу docker. Перезайдите в терминал (logout/login), чтобы работать без sudo.${NC}"
fi

# ======================
# УТИЛИТЫ И ОПТИМИЗАЦИЯ
# ======================
echo -e "${YELLOW}🔹 Устанавливаем утилиты...${NC}"
need_sudo apt-get install -y \
htop screen tmux ncdu nnn git tree jq \
zip unzip net-tools iputils-ping traceroute \
nano vim fail2ban ufw lxterminal

echo -e "${YELLOW}🔹 Оптимизируем систему...${NC}"
need_sudo sysctl -w vm.max_map_count=262144
grep -q "vm.max_map_count" /etc/sysctl.conf || echo "vm.max_map_count=262144" | need_sudo tee -a /etc/sysctl.conf >/dev/null

# Настройка файрвола
need_sudo ufw allow 22/tcp
need_sudo ufw --force enable

# Чистим dead screen-сессии
screen -wipe >/dev/null 2>&1 || true

# Проверка версий
echo -e "${GREEN}✅ Всё готово! Docker и Docker Compose v2 установлены.${NC}"
echo -e "${YELLOW}Перезайдите в терминал или выполните 'source ~/.bashrc', чтобы активировать алиасы (update, clean, speed).${NC}"
docker --version
docker compose version
