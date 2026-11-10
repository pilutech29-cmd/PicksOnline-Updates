#!/usr/bin/env bash
# Baja la parrilla (parrilla.json) y los videos nuevos; reinicia la emisión solo si algo cambió.
set -uo pipefail
DIR=/opt/simititv
URL="https://raw.githubusercontent.com/pilutech29-cmd/PicksOnline-Updates/main/servidor/parrilla.json"
cd "$DIR" || exit 1
curl -fsSL "$URL?t=$(date +%s)" -o parrilla.nueva || exit 0
jq -e '.videos|length>0' parrilla.nueva >/dev/null || exit 0
: > lista.nueva
for u in $(jq -r '.videos[]' parrilla.nueva); do
  f="videos/$(basename "${u%%\?*}")"
  if [ ! -s "$f" ]; then echo "Bajando $u"; curl -fL --retry 3 -o "$f.part" "$u" && mv "$f.part" "$f"; fi
  [ -s "$f" ] && echo "file '$DIR/$f'" >> lista.nueva
done
M=$(jq -r '.musica // ""' parrilla.nueva)
if [ -n "$M" ]; then
  mf="videos/musica-$(basename "${M%%\?*}")"
  [ -s "$mf" ] || curl -fL --retry 3 -o "$mf" "$M"
  echo "$DIR/$mf" > musica.nueva
else : > musica.nueva; fi
CAMBIO=0
for x in lista musica; do cmp -s "$x.nueva" "$x.txt" || { mv "$x.nueva" "$x.txt"; CAMBIO=1; }; rm -f "$x.nueva"; done
mv parrilla.nueva parrilla.json
# Borra videos que ya no están en la parrilla
for f in videos/*; do grep -q "$f" lista.txt musica.txt 2>/dev/null || rm -f "$f"; done
[ "$CAMBIO" = 1 ] && systemctl is-active --quiet simititv && systemctl restart simititv
exit 0
