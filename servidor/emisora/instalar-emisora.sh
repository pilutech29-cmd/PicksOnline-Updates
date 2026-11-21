#!/usr/bin/env bash
# Simití TV · instala la EMISORA CON MARCO (video en ventana + anunciantes + cintillo), salida HLS, sin YouTube.
# Uso:  curl -fsSL https://raw.githubusercontent.com/pilutech29-cmd/PicksOnline-Updates/main/servidor/emisora/instalar-emisora.sh | sudo bash
set -euo pipefail
main() {
BASE="https://raw.githubusercontent.com/pilutech29-cmd/PicksOnline-Updates/main/servidor/emisora"
D=/opt/simititv/emisora
echo "== Simití TV: instalando la emisora =="
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq ffmpeg nginx jq curl openssl fonts-dejavu-core >/dev/null
mkdir -p "$D/videos" "$D/norm" "$D/marcos" /var/www/hls /etc/simititv
for f in emitir-emisora.sh normalizar.sh sincronizar-emisora.sh; do curl -fsSL "$BASE/$f?t=$(date +%s)" -o "$D/$f"; done
chmod +x "$D"/*.sh
curl -fsSL "$BASE/simititv-emisora.service" -o /etc/systemd/system/simititv-emisora.service
[ -s "$D/cintillo.txt" ] || echo "Bienvenidos a Simití TV, la emisora de nuestro pueblo   ●   Anuncia tu negocio: WhatsApp 305 257 7821   ●   " > "$D/cintillo.txt"

# Certificado de origen (para usarlo detrás de Cloudflare)
if [ ! -s /etc/simititv/origen.crt ]; then
  openssl req -x509 -nodes -newkey rsa:2048 -days 3650 -subj "/CN=senal.simititv.com" \
    -keyout /etc/simititv/origen.key -out /etc/simititv/origen.crt >/dev/null 2>&1
fi
curl -fsSL "$BASE/senal-nginx.conf" -o /etc/nginx/sites-available/simititv-senal
ln -sf /etc/nginx/sites-available/simititv-senal /etc/nginx/sites-enabled/simititv-senal
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl enable --now nginx >/dev/null 2>&1 && systemctl reload nginx
if command -v ufw >/dev/null && ufw status | grep -q active; then ufw allow 'Nginx Full' >/dev/null || true; fi

echo "== Bajando y preparando videos (puede tardar unos minutos la primera vez) =="
"$D/sincronizar-emisora.sh" < /dev/null
( crontab -l 2>/dev/null | grep -v sincronizar-emisora.sh; echo "*/30 * * * * $D/sincronizar-emisora.sh >> /var/log/simititv-emisora-sync.log 2>&1" ) | crontab -

systemctl daemon-reload
systemctl enable --now simititv-emisora
sleep 15
IP=$(curl -fsS https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')
if systemctl is-active --quiet simititv-emisora && [ -s /var/www/hls/simiti.m3u8 ]; then
  echo
  echo "✅ La emisora está al aire."
  echo "   Prueba en VLC (Medio > Abrir ubicación de red):  http://$IP/hls/simiti.m3u8"
  echo "   Ver registro:  journalctl -u simititv-emisora -f"
else
  echo "⚠️  Revisa esto y mándaselo a Claude:"; journalctl -u simititv-emisora -n 30 --no-pager
fi
}
main "$@" < /dev/null
