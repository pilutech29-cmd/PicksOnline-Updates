#!/usr/bin/env bash
# Simití TV · contador de espectadores. Uso: curl -fsSL .../instalar-conteo.sh | bash
set -e
main(){
R=https://raw.githubusercontent.com/pilutech29-cmd/PicksOnline-Updates/main/servidor
echo "== Simití TV · contador de espectadores =="
mkdir -p /opt/simititv/conteo
curl -fsSL "$R/conteo/simititv-log.conf" -o /etc/nginx/conf.d/simititv-log.conf
curl -fsSL "$R/emisora/senal-nginx.conf" -o /etc/nginx/sites-available/simititv-senal
curl -fsSL "$R/conteo/contar.sh" -o /opt/simititv/conteo/contar.sh; chmod +x /opt/simititv/conteo/contar.sh
curl -fsSL "$R/conteo/conectados.html" -o /var/www/hls/conectados.html
curl -fsSL "$R/conteo/simititv-conteo.service" -o /etc/systemd/system/simititv-conteo.service
nginx -t && systemctl reload nginx
systemctl daemon-reload && systemctl enable --now simititv-conteo >/dev/null 2>&1 && systemctl restart simititv-conteo
echo
echo "LISTO. Mira los conectados en: https://senal.simititv.com/hls/conectados.html"
echo "(La emisora no se reinició.)"
}
main "$@" < /dev/null
