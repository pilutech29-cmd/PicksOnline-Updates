#!/usr/bin/env bash
# Simití TV · baja la parrilla, la publicidad y los marcos; prepara los videos (960x540); arma la lista:
# cada N videos entra un anuncio, turnándose. Lo vencido ('hasta') sale solo. Reinicia la emisora si algo cambió.
set -uo pipefail
D=/opt/simititv/emisora
BASE="https://raw.githubusercontent.com/pilutech29-cmd/PicksOnline-Updates/main/servidor"
cd "$D" || exit 1
mkdir -p videos norm marcos
curl -fsSL "$BASE/parrilla.json?t=$(date +%s)" -o parrilla.nueva || exit 0
jq -e '.videos|length>0' parrilla.nueva >/dev/null || exit 0
HOY=$(TZ=America/Bogota date +%F)

preparar() {  # url -> imprime la ruta normalizada (o nada si falla)
  local u="$1" n f g; n="$(basename "${u%%\?*}")"; f="videos/$n"; g="norm/$n"
  [ -s "$f" ] || { echo "Bajando $n" >&2; curl -fsSL --retry 3 -o "$f.part" "$u" && mv "$f.part" "$f"; }
  [ -s "$f" ] && [ ! -s "$g" ] && { echo "Preparando $n" >&2; "$D/normalizar.sh" "$f" "$g.tmp.mp4" && mv "$g.tmp.mp4" "$g"; }
  [ -s "$g" ] && echo "$D/$g"
}
mapfile -t C < <(for u in $(jq -r '.videos[]' parrilla.nueva); do preparar "$u"; done)
mapfile -t A < <(for u in $(jq -r --arg h "$HOY" '(.publicidad // [])[] | select((.hasta // "9999") >= $h) | .url' parrilla.nueva); do preparar "$u"; done)
N=$(jq -r '.cadaCuantos // 3' parrilla.nueva)

: > lista.nueva
if [ ${#A[@]} -eq 0 ]; then
  for c in "${C[@]}"; do echo "file '$c'" >> lista.nueva; done
else
  k=0; cnt=0
  for r in $(seq 1 ${#A[@]}); do
    for c in "${C[@]}"; do
      echo "file '$c'" >> lista.nueva; cnt=$((cnt+1))
      if [ $((cnt % N)) -eq 0 ]; then echo "file '${A[$((k % ${#A[@]}))]}'" >> lista.nueva; k=$((k+1)); fi
    done
  done
fi

# Cintillo
jq -r --arg h "$HOY" '[(.cintillo // [])[] | select((.hasta // "9999") >= $h) | .texto] | join("     ●     ")' parrilla.nueva > cintillo.nuevo
if [ -s cintillo.nuevo ] && [ "$(tr -d '[:space:]' < cintillo.nuevo)" != "" ]; then sed -i 's/$/     ●     /' cintillo.nuevo; cmp -s cintillo.nuevo cintillo.txt || mv cintillo.nuevo cintillo.txt; fi
rm -f cintillo.nuevo

# Marcos (anunciantes), uno cada 20 s
curl -fsSL "$BASE/emisora/marcos/lista.txt?t=$(date +%s)" -o marcos/lista.txt || true
: > marcos.nuevo
while read -r m h; do [ -n "${m:-}" ] || continue
  [ -n "${h:-}" ] && [[ "$h" < "$HOY" ]] && continue
  curl -fsSL "$BASE/emisora/marcos/$m?t=$(date +%s)" -o "marcos/$m.part" && mv "marcos/$m.part" "marcos/$m"
  [ -s "marcos/$m" ] && { echo "file '$D/marcos/$m'"; echo "duration 20"; } >> marcos.nuevo
done < marcos/lista.txt
[ -s marcos.nuevo ] && tail -n 2 marcos.nuevo | head -n 1 >> marcos.nuevo

CAMBIO=0
[ -s lista.nueva ] && { cmp -s lista.nueva lista.txt || { mv lista.nueva lista.txt; CAMBIO=1; }; }
[ -s marcos.nuevo ] && { cmp -s marcos.nuevo marcos.txt || { mv marcos.nuevo marcos.txt; CAMBIO=1; }; }
rm -f lista.nueva marcos.nuevo; mv parrilla.nueva parrilla.json
[ "$CAMBIO" = 1 ] && systemctl is-active --quiet simititv-emisora && systemctl restart simititv-emisora
exit 0
