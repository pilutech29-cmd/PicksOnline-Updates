#!/usr/bin/env bash
# Simití TV · instala la entrada en vivo para OBS. Uso: curl -fsSL .../instalar-vivo.sh | sudo bash
set -e
main(){
R=https://raw.githubusercontent.com/pilutech29-cmd/PicksOnline-Updates/main/servidor
echo "== Simití TV · entrada en vivo para OBS =="
apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq libnginx-mod-rtmp sudo openssl >/dev/null
mkdir -p /opt/simititv/vivo /etc/simititv
for f in relevo-vivo.sh al-aire.sh; do curl -fsSL "$R/vivo/$f" -o /opt/simititv/vivo/$f; chmod +x /opt/simititv/vivo/$f; done
curl -fsSL "$R/vivo/simititv-vivo.service" -o /etc/systemd/system/simititv-vivo.service
curl -fsSL "$R/vivo/rtmp.conf" -o /etc/nginx/simititv-rtmp.conf
curl -fsSL "$R/emisora/emitir-emisora.sh" -o /opt/simititv/emisora/emitir-emisora.sh; chmod +x /opt/simititv/emisora/emitir-emisora.sh
[ -s /etc/simititv/clave-vivo.txt ] || openssl rand -hex 8 > /etc/simititv/clave-vivo.txt
chmod 644 /etc/simititv/clave-vivo.txt
CLAVE=$(cat /etc/simititv/clave-vivo.txt)
cat > /etc/nginx/sites-enabled/simititv-vivo-clave <<C
server { listen 127.0.0.1:8935; location /auth { if (\$arg_name = "$CLAVE") { return 200; } return 403; } }
C
grep -q simititv-rtmp.conf /etc/nginx/nginx.conf || echo 'include /etc/nginx/simititv-rtmp.conf;' >> /etc/nginx/nginx.conf
echo 'www-data ALL=(root) NOPASSWD: /usr/bin/systemctl start simititv-vivo, /usr/bin/systemctl stop simititv-vivo' > /etc/sudoers.d/simititv-vivo
chmod 440 /etc/sudoers.d/simititv-vivo; visudo -cf /etc/sudoers.d/simititv-vivo >/dev/null
if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then ufw allow 1935/tcp >/dev/null; fi
systemctl daemon-reload
nginx -t && systemctl restart nginx
systemctl restart simititv-emisora
IP=$(curl -fsS4 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')
echo
echo "LISTO. En OBS > Ajustes > Emisión > Servicio: Personalizado"
echo "  Servidor: rtmp://$IP/live"
echo "  Clave:    $CLAVE"
echo "Al terminar la transmisión, la app vuelve sola a la parrilla."
}
main "$@" < /dev/null
