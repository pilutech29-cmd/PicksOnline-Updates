#!/usr/bin/env bash
# Simití TV · instalador de la transmisión 24/7 (Ubuntu 24.04)
# Uso:  curl -fsSL https://raw.githubusercontent.com/pilutech29-cmd/PicksOnline-Updates/main/servidor/instalar.sh | sudo bash
set -euo pipefail
BASE="https://raw.githubusercontent.com/pilutech29-cmd/PicksOnline-Updates/main/servidor"
DIR=/opt/simititv
echo "== Simití TV: instalando =="
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq ffmpeg curl jq ufw fail2ban >/dev/null
mkdir -p "$DIR/videos" /etc/simititv
curl -fsSL "$BASE/emitir.sh"      -o "$DIR/emitir.sh"
curl -fsSL "$BASE/sincronizar.sh" -o "$DIR/sincronizar.sh"
curl -fsSL "$BASE/simititv.service" -o /etc/systemd/system/simititv.service
chmod +x "$DIR"/*.sh

# Clave de transmisión de YouTube: se guarda SOLO en este servidor
if [ ! -s /etc/simititv/clave ]; then
  echo
  echo "Pega la CLAVE DE TRANSMISIÓN de YouTube (YouTube Studio > Emitir en vivo > Transmisión)."
  echo "No se mostrará en pantalla. Presiona Enter al terminar:"
  read -rs CLAVE < /dev/tty
  [ -n "$CLAVE" ] || { echo "No escribiste la clave. Vuelve a ejecutar el instalador."; exit 1; }
  printf '%s' "$CLAVE" > /etc/simititv/clave
  chmod 600 /etc/simititv/clave
  echo "Clave guardada."
fi

# Seguridad básica
ufw allow OpenSSH >/dev/null; ufw --force enable >/dev/null
systemctl enable --now fail2ban >/dev/null 2>&1 || true

# Descargar la parrilla y revisar cada 30 minutos si hay videos nuevos
"$DIR/sincronizar.sh"
( crontab -l 2>/dev/null | grep -v sincronizar.sh; echo "*/30 * * * * $DIR/sincronizar.sh >> /var/log/simititv-sync.log 2>&1" ) | crontab -

systemctl daemon-reload
systemctl enable --now simititv
sleep 5
echo
if systemctl is-active --quiet simititv; then
  echo "✅ Simití TV está transmitiendo a YouTube las 24 horas."
  echo "   Ver estado:   systemctl status simititv"
  echo "   Ver registro: journalctl -u simititv -f"
else
  echo "⚠️  No arrancó. Muestra esto a soporte:"; journalctl -u simititv -n 30 --no-pager
fi
