#!/usr/bin/env bash
# Emite la parrilla en bucle a YouTube. El video va tal cual (sin recodificar); el audio es la música o silencio.
DIR=/opt/simititv
CLAVE=$(cat /etc/simititv/clave)
DESTINO="rtmp://a.rtmp.youtube.com/live2/$CLAVE"
M=$(cat "$DIR/musica.txt" 2>/dev/null)
if [ -n "$M" ] && [ -s "$M" ]; then AUDIO=(-stream_loop -1 -i "$M"); else AUDIO=(-f lavfi -i anullsrc=r=44100:cl=stereo); fi
exec ffmpeg -hide_banner -loglevel warning -re -stream_loop -1 -f concat -safe 0 -i "$DIR/lista.txt" "${AUDIO[@]}" \
  -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -b:a 128k -ar 44100 -shortest -f flv "$DESTINO"
