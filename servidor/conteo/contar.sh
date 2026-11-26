#!/usr/bin/env bash
# Simití TV · cuenta cuántas conexiones distintas están viendo la señal (últimos 45 s) cada 10 s.
LOG=/var/log/nginx/simiti-hls.log; OUT=/var/www/hls; EST=/var/lib/simititv-conteo
mkdir -p "$EST"
while true; do
  t=$(( $(date +%s) - 45 ))
  n=$(tail -n 40000 "$LOG" 2>/dev/null | awk -v t="$t" '$1>=t && $4 ~ /\.m3u8$/ { ip=($2!="-")?$2:$3; if(!(ip in u)){u[ip]=1;c++} } END{print c+0}')
  hoy=$(TZ=America/Bogota date +%F); pf="$EST/pico-$hoy"
  pico=$(cat "$pf" 2>/dev/null || echo 0)
  [ "$n" -gt "$pico" ] && { pico=$n; echo "$pico" > "$pf"; }
  hora=$(TZ=America/Bogota date '+%I:%M:%S %p')
  printf '{"ahora":%d,"picoHoy":%d,"hora":"%s"}\n' "$n" "$pico" "$hora" > "$OUT/.conectados.tmp" && mv "$OUT/.conectados.tmp" "$OUT/conectados.json"
  sleep 10
done
