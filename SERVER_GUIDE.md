# Полное руководство по настройке и обслуживанию сервера SPT

Этот файл содержит описание текущей архитектуры сервера, инструкции по его управлению, а также пошаговые руководства по изменению доменов, портов и настроек прокси-сервера.

---

## 🛠 Текущая архитектура сервера

Сервер работает на базе **Arch Linux** и включает следующие компоненты:

1. **Бэкенд (FastAPI / Uvicorn)**
   * **Где находится:** `/home/vdserv/SPSPSP/Backend`
   * **Порт:** `8000` (слушает на всех интерфейсах `0.0.0.0`)
   * **Служба systemd:** `spt-backend.service`

2. **База данных (MariaDB)**
   * **Тип:** MySQL-совместимая СУБД
   * **Служба systemd:** `mariadb.service`

3. **Cloudflare Tunnel (Агент cloudflared)**
   * **Назначение:** Безопасный проброс локального порта `8000` во внешнюю сеть без открытия портов.
   * **Домен:** `spotfynder.dpdns.org`
   * **Служба systemd:** `cloudflare-tunnel.service`
   * **Конфиг:** `/etc/cloudflared/config.yml`

4. **Системный прокси (HTTP Proxy)**
   * **Назначение:** Стабильный обход сетевых блокировок провайдера до серверов Cloudflare Edge.
   * **Адрес прокси:** `152.232.71.55:8000`
   * **Где настроен:** `/etc/environment` (глобально) и внутри юнитов systemd для туннеля и бэкенда.

---

## 🚀 Управление сервером: Основные команды

Для удобства в домашней директории пользователя создан скрипт полного перезапуска:
```bash
/home/vdserv/restart_server.sh
```
Он автоматически получает обновления из Git, освобождает порт, проверяет базу данных, сбрасывает зависшие службы и перезапускает бэкенд, туннель и Nginx.

### Просмотр логов в реальном времени:
* **Логи бэкенда:**
  ```bash
  journalctl -u spt-backend.service -n 50 -f
  ```
* **Логи туннеля Cloudflare:**
  ```bash
  journalctl -u cloudflare-tunnel.service -n 50 -f
  ```

---

## 🔄 Как изменить настройки прокси-сервера

Если вам потребуется сменить прокси-сервер или отключить его полностью, выполните следующие действия:

### Вариант А. Полное отключение прокси (прямое подключение)
1. **Очистите глобальное окружение:**
   Откройте `/etc/environment` с правами суперпользователя:
   ```bash
   sudo nano /etc/environment
   ```
   Удалите или закомментируйте (`#`) все строки с переменными `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY`.

2. **Очистите настройки служб systemd:**
   Откройте файл службы туннеля:
   ```bash
   sudo nano /etc/systemd/system/cloudflare-tunnel.service
   ```
   Удалите строки:
   ```ini
   Environment="HTTP_PROXY=..."
   Environment="HTTPS_PROXY=..."
   Environment="NO_PROXY=..."
   ```
   Сделайте то же самое для службы бэкенда:
   ```bash
   sudo nano /etc/systemd/system/spt-backend.service
   ```

3. **Примените изменения:**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart cloudflare-tunnel.service spt-backend.service
   ```

### Вариант Б. Смена IP или авторизации прокси
Просто замените адрес и учетные данные прокси во всех указанных выше местах (`/etc/environment`, `/etc/systemd/system/cloudflare-tunnel.service` и `/etc/systemd/system/spt-backend.service`), после чего выполните:
```bash
sudo systemctl daemon-reload
sudo systemctl restart cloudflare-tunnel.service spt-backend.service
```

---

## 🌐 Как изменить доменное имя проекта

Если вы захотите перенести проект на другой домен/поддомен:

1. **Привяжите новый домен в Cloudflare:**
   Убедитесь, что ваш новый домен обслуживается DNS-серверами Cloudflare.

2. **Авторизуйте туннель для нового домена:**
   Свяжите ваш туннель с новым доменным именем:
   ```bash
   cloudflared tunnel route dns spt-tunnel <ваш_новый_домен>
   ```

3. **Обновите конфигурационный файл туннеля:**
   Откройте конфиг:
   ```bash
   sudo nano /etc/cloudflared/config.yml
   ```
   В секции `ingress` замените старый хост на новый:
   ```yaml
   ingress:
     - hostname: <ваш_новый_домен>
       service: http://127.0.0.1:8000
     - service: http_status:404
   ```

4. **Обновите CORS в коде бэкенда:**
   Откройте `Backend/app/main.py` и добавьте новый домен в список разрешенных CORS-оригинов (или оставьте маску `allow_origin_regex="https?://.*"`, которая автоматически разрешает любые домены).

5. **Перезапустите туннель:**
   ```bash
   sudo systemctl restart cloudflare-tunnel.service
   ```

---

## 🔌 Как изменить порты бэкенда

Если вы захотите, чтобы бэкенд работал на другом порту (например, `9000` вместо `8000`):

1. **Измените порт в службе бэкенда:**
   ```bash
   sudo nano /etc/systemd/system/spt-backend.service
   ```
   В строке `ExecStart` измените параметр `--port 8000` на `--port 9000`.

2. **Измените целевой порт в туннеле:**
   ```bash
   sudo nano /etc/cloudflared/config.yml
   ```
   Замените `service: http://127.0.0.1:8000` на `service: http://127.0.0.1:9000`.

3. **Примените изменения и перезапустите службы:**
   ```bash
   sudo systemctl daemon-reload
   /home/vdserv/restart_server.sh
   ```
