#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  Развёртывание сайта «Фантик» на своём сервере (Caddy)
#  Причина: домен github.io блокируется в РФ — хостим у себя.
# ============================================================
set -e

# --- НАСТРОЙКИ (поправь под себя, если пути другие) ---
WEBROOT="${WEBROOT:-/var/www/fantik}"      # куда кладём сайт
CADDYFILE="${CADDYFILE:-/etc/caddy/Caddyfile}"
DOMAIN="${DOMAIN:-}"                        # напр. shtab.duckdns.org
PORT="${PORT:-8443}"                        # порт Caddy
# -------------------------------------------------------

echo "==> 1. Создаю каталог сайта: $WEBROOT"
sudo mkdir -p "$WEBROOT"

echo "==> 2. Копирую index.html"
sudo cp -f index.html "$WEBROOT/index.html"
sudo chmod 644 "$WEBROOT/index.html"

echo "==> 3. Проверяю Caddy"
if ! command -v caddy >/dev/null 2>&1; then
  echo "!! Caddy не найден. Установи: sudo apt install -y caddy"
  exit 1
fi

echo "==> 4. Добавляю блок сайта в Caddyfile (если ещё нет)"
if [ -n "$DOMAIN" ]; then
  if ! sudo grep -q "$DOMAIN" "$CADDYFILE" 2>/dev/null; then
    sudo tee -a "$CADDYFILE" >/dev/null <<EOF

# --- Фантик (детская парикмахерская) ---
$DOMAIN:$PORT {
    root * $WEBROOT
    file_server
    encode gzip
}
EOF
    echo "    блок добавлен"
  else
    echo "    блок уже есть — пропускаю"
  fi
else
  echo "    DOMAIN не задан — добавь блок вручную:"
  echo "    root * $WEBROOT ; file_server"
fi

echo "==> 5. Перезагружаю Caddy"
sudo caddy validate --config "$CADDYFILE" 2>/dev/null || true
sudo systemctl reload caddy 2>/dev/null || sudo systemctl restart caddy

echo ""
echo "ГОТОВО. Сайт лежит в: $WEBROOT/index.html"
if [ -n "$DOMAIN" ]; then
  echo "Открывай: https://$DOMAIN:$PORT/"
fi
echo ""
echo "Запуск с параметрами, например:"
echo "  DOMAIN=shtab.duckdns.org WEBROOT=/var/www/fantik bash deploy_fantik.sh"
