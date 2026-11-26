#!/usr/bin/env bash
# Simití TV · Emisora con marco: video en la ventana + anunciantes + cintillo + hora. Sale por HLS (sin YouTube).
D=${EMISORA_DIR:-/opt/simititv/emisora}
OUT=${HLS_DIR:-/var/www/hls}
F=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf
mkdir -p "$OUT"   # sin borrar: así la app no se corta al volver de una transmisión en vivo
FILTRO="[1:v]fps=25,scale=1280:720,format=yuv420p[bg];\
[bg][0:v]overlay=21:21:shortest=0[a];\
[a]drawtext=fontfile=$F:textfile=$D/cintillo.txt:reload=1:fontsize=18:fontcolor=white:y=696:x=w-mod(t*90\,w+tw)[b];\
[b]drawbox=x=0:y=689:w=146:h=31:color=0xd32f2f:t=fill,\
drawtext=fontfile=$F:text='SIMITÍ AL DÍA':fontsize=14:fontcolor=white:x=(146-tw)/2:y=698,\
drawtext=fontfile=$F:text='%{localtime\:%I\\\\\\:%M %p}':fontsize=21:fontcolor=white:x=1186-tw/2:y=145-th/2[v]"
exec ffmpeg -nostdin -hide_banner -loglevel warning \
  -re -stream_loop -1 -f concat -safe 0 -i "$D/lista.txt" \
  -re -stream_loop -1 -f concat -safe 0 -i "$D/marcos.txt" \
  -filter_complex "$FILTRO" -map "[v]" -map 0:a:0 \
  -c:v libx264 -preset veryfast -b:v 1500k -maxrate 1800k -bufsize 3000k -g 50 -keyint_min 50 -sc_threshold 0 \
  -c:a aac -b:a 128k -ar 44100 -ac 2 \
  -f hls -hls_time 4 -hls_list_size 15 -hls_delete_threshold 15 -hls_flags delete_segments+omit_endlist+independent_segments+append_list+discont_start \
  -hls_segment_filename "$OUT/simiti%05d.ts" "$OUT/simiti.m3u8"
