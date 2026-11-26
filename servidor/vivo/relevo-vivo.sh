#!/usr/bin/env bash
# Simití TV · pasa lo que llega de OBS (RTMP) a la misma señal HLS de la app.
OUT=${HLS_DIR:-/var/www/hls}
CLAVE=$(cat /etc/simititv/clave-vivo.txt)
sleep 1
exec ffmpeg -nostdin -hide_banner -loglevel warning -rw_timeout 10000000 \
  -i "rtmp://127.0.0.1/live/$CLAVE" \
  -vf "fps=25,scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,format=yuv420p" \
  -map 0:v:0 -map 0:a:0? \
  -c:v libx264 -preset veryfast -b:v 1800k -maxrate 2200k -bufsize 3600k -g 50 -keyint_min 50 -sc_threshold 0 \
  -c:a aac -b:a 128k -ar 44100 -ac 2 \
  -f hls -hls_time 4 -hls_list_size 15 -hls_delete_threshold 15 -hls_flags delete_segments+omit_endlist+independent_segments+append_list+discont_start \
  -hls_segment_filename "$OUT/simiti%05d.ts" "$OUT/simiti.m3u8"
