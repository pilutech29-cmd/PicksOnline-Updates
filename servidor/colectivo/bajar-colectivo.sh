#!/usr/bin/env bash
# Simití TV · baja los videos del Colectivo «Pescado, Sombrero y Tambó» (Simití, memoria viva) para la emisora.
# Uso: curl -fsSL .../bajar-colectivo.sh | bash
main(){
OUT=/var/www/hls/colectivo
mkdir -p "$OUT"
echo "== Simití TV · videos del Colectivo «Pescado, Sombrero y Tambó» =="
curl -fsSL https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp && chmod +x /usr/local/bin/yt-dlp
command -v python3 >/dev/null || { apt-get update -qq && apt-get install -y -qq python3 >/dev/null; }
bajar(){ # $1 id  $2 nombre
  [ -s "$OUT/$2.mp4" ] && { echo "Ya estaba: $2"; return; }
  yt-dlp -q --no-warnings --no-playlist -f "bv*[height<=720][ext=mp4]+ba[ext=m4a]/b[height<=720]/b" \
    --merge-output-format mp4 -o "$OUT/$2.%(ext)s" "https://www.youtube.com/watch?v=$1" \
    && echo "OK: $2" || echo "FALLÓ: $2"
}
bajar QygzfynEjhE colectivo-trailer
bajar 7UxJyLrPRqU colectivo-ep1-marcelo
bajar OMOvLi8MZX8 colectivo-ep2-juanita
bajar RyNlRn_9ezQ colectivo-ep3-libardo
bajar S4zscySQ8ok colectivo-ep4-hugo
echo; ls -lh "$OUT"
}
main "$@" < /dev/null
