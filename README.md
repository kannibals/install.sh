# Server Setup Script 🔧

Автоматическая настройка сервера с Docker, утилитами и оптимизациями (для Ubuntu/Debian).  
**Работает только от root!**  

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Shell Check](https://github.com/stanislavcrypto/install.sh/actions/workflows/shellcheck.yml/badge.svg)

## 📦 Что устанавливается
- **Docker** + **Docker Compose v2** (без `sudo`)
- Системные утилиты: `htop`, `tmux`, `ncdu`, `jq`, `fail2ban` и др.
- Оптимизации: 
  - Настройка `vm.max_map_count` для Docker
  - Файрвол (`ufw`) с открытыми портами 22, 80, 443

## 🚀 Быстрый старт
```bash
# Запуск от root (не рекомендуется для production!)
bash <(curl -fsSL https://raw.githubusercontent.com/stanislavcrypto/install.sh/main/install.sh)
