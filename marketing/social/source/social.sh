#!/bin/bash
# Elapsa social video (TikTok, Instagram Reels, YouTube Shorts, 小红书), 1080x1920, 30 fps.
#
#   social.sh en <output.mp4>    English, from take1.mov
#   social.sh zh <output.mp4>    简体中文 (小红书), from take-zh.mov
#
# Hook card (2.2 s) → the app recording with captions (same six pieces as the App
# Store preview) → end card (2.8 s), with 0.3 s crossfades. The soundtrack is
# original music from music.py, so it's free to use anywhere; a trending sound added
# in the app when posting can replace it.
set -e
cd "$(dirname "$0")"
LANG_CODE="$1"
OUT="$2"
L="social-$LANG_CODE"
mkdir -p "$L"
python3 -I social_layers.py "$L" "$LANG_CODE" >/dev/null

if [ "$LANG_CODE" = "zh" ]; then
  TAKE=take-zh.mov
  CUTS="0.3:6.3 6.3:9.6 9.6:12.1 13.6:15.1 15.1:18.5 20.2:23.5"
else
  TAKE=take1.mov
  CUTS="2.0:8.0 8.0:11.3 11.3:13.8 45.5:47.0 52.9:56.3 60.5:64.0"
fi

set -- $CUTS
LEN=(); SEGS=""; i=0
for c in "$@"; do
  a=${c%:*}; b=${c#*:}
  SEGS="${SEGS}[s$i]trim=$a:$b,setpts=PTS-STARTPTS[v$i];"
  LEN[$i]=$(echo "$b - $a" | bc)
  i=$((i+1))
done
T1=${LEN[0]}
T2=$(echo "${LEN[0]} + ${LEN[1]} + ${LEN[2]}" | bc)
T3=$(echo "$T2 + ${LEN[3]} + ${LEN[4]}" | bc)
BODY=$(echo "$T3 + ${LEN[5]}" | bc)
HOOK=2.2
END=2.8
X=0.3
TOTAL=$(echo "$HOOK + $BODY + $END - 2 * $X" | bc)
OFF1=$(echo "$HOOK - $X" | bc)
OFF2=$(echo "$HOOK + $BODY - 2 * $X" | bc)

CAP="[4:v]format=rgba,fade=t=in:st=0:d=0.3:alpha=1[c0];[5:v]format=rgba,fade=t=in:st=$T1:d=0.3:alpha=1[c1];[6:v]format=rgba,fade=t=in:st=$T2:d=0.3:alpha=1[c2];[7:v]format=rgba,fade=t=in:st=$T3:d=0.3:alpha=1[c3]"

ffmpeg -hide_banner -loglevel error -y \
  -i "$TAKE" \
  -loop 1 -t "$BODY" -i "$L/bg.png" \
  -loop 1 -t "$BODY" -i "$L/mask.png" \
  -loop 1 -t "$HOOK" -i "$L/hook.png" \
  -loop 1 -t "$BODY" -i "$L/cap0.png" \
  -loop 1 -t "$BODY" -i "$L/cap1.png" \
  -loop 1 -t "$BODY" -i "$L/cap2.png" \
  -loop 1 -t "$BODY" -i "$L/cap3.png" \
  -loop 1 -t "$END" -i "$L/end.png" \
  -f lavfi -t "$TOTAL" -i anullsrc=r=44100:cl=stereo \
  -filter_complex "[0:v]fps=30,split=6[s0][s1][s2][s3][s4][s5];${SEGS}[v0][v1][v2][v3][v4][v5]concat=n=6:v=1:a=0,scale=820:1782:flags=lanczos,format=rgba[scr];[2:v]format=gray,fps=30[m];[scr][m]alphamerge[rounded];[1:v]fps=30,format=rgba[bg];[bg][rounded]overlay=130:560:shortest=1[b1];${CAP};[b1][c0]overlay=0:0:enable='lt(t,$T1)'[b2];[b2][c1]overlay=0:0:enable='between(t,$T1,$T2)'[b3];[b3][c2]overlay=0:0:enable='between(t,$T2,$T3)'[b4];[b4][c3]overlay=0:0:enable='gte(t,$T3)',format=yuv420p,settb=1/30[body];[3:v]fps=30,format=yuv420p,settb=1/30[hook];[8:v]fps=30,format=yuv420p,settb=1/30[end];[hook][body]xfade=transition=fade:duration=$X:offset=$OFF1[hb];[hb][end]xfade=transition=fade:duration=$X:offset=$OFF2,format=yuv420p[v]" \
  -map "[v]" -map 9:a -t "$TOTAL" -r 30 \
  -c:v libx264 -profile:v high -preset slow -crf 18 -c:a aac -b:a 128k -movflags +faststart \
  "$L/silent.mp4"

# Original music (music.py), with a chime at each scene change and the end card.
C1=$OFF1
C2=$(echo "$OFF1 + $T1" | bc)
C3=$(echo "$OFF1 + $T2" | bc)
C4=$(echo "$OFF1 + $T3" | bc)
python3 -I music.py "$L/music.wav" "$TOTAL" "$C1,$C2,$C3,$C4" "$OFF2"
ffmpeg -hide_banner -loglevel error -y -i "$L/silent.mp4" -i "$L/music.wav" \
  -map 0:v -map 1:a -c:v copy -c:a aac -b:a 192k -shortest -movflags +faststart "$OUT"
echo "$OUT: ${TOTAL}s with music"
