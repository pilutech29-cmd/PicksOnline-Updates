#!/usr/bin/env bash
# Convierte un video a 960x540, 25 fps, h264 + aac estéreo (con audio en silencio si no trae)
in="$1"; out="$2"
VF="scale=960:540:force_original_aspect_ratio=decrease,pad=960:540:(ow-iw)/2:(oh-ih)/2,fps=25,setsar=1,format=yuv420p"
if ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$in" | grep -q .; then
  ffmpeg -nostdin -hide_banner -loglevel error -y -i "$in" -vf "$VF" -c:v libx264 -preset veryfast -crf 23 -g 50 \
    -c:a aac -ar 44100 -ac 2 -b:a 128k -movflags +faststart "$out"
else
  ffmpeg -nostdin -hide_banner -loglevel error -y -i "$in" -f lavfi -i anullsrc=r=44100:cl=stereo -vf "$VF" \
    -map 0:v:0 -map 1:a:0 -shortest -c:v libx264 -preset veryfast -crf 23 -g 50 -c:a aac -ar 44100 -ac 2 -b:a 128k -movflags +faststart "$out"
fi
