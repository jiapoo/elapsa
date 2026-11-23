#!/bin/bash
# Captioned Elapsa App Store preview: crimson background, caption on top,
# the recording in a rounded screen below. 886x1920, 30 fps, silent stereo AAC.
#
#   compose.sh en <output.mp4>     from take1.mov  (English UI)
#   compose.sh zh <output.mp4>     from take-zh.mov (简体中文 UI)
#   compose.sh zh-hant <output.mp4> from take-zh-hant.mov (繁體中文 UI)
#
# Each take is cut into six pieces (wallet, opening the passport, its detail,
# opening Edit, scrolling to the reminders, picking reminders). The four
# captions switch at the start of pieces 2, 4 and 6.
set -e
cd "$(dirname "$0")"
LANG_CODE="$1"
OUT="$2"

if [ "$LANG_CODE" = "zh" ]; then
  TAKE=take-zh.mov
  CUTS="0.3:6.3 6.3:9.6 9.6:12.1 13.6:15.1 15.1:18.5 20.2:23.5"
elif [ "$LANG_CODE" = "zh-hant" ]; then
  # 7.4-15 is a missed tap that scrolled the list; the cut skips it.
  TAKE=take-zh-hant.mov
  CUTS="0.3:6.3 15.2:18.5 18.7:21.2 21.8:23.3 23.3:26.7 28.0:31.1"
else
  TAKE=take1.mov
  CUTS="2.0:8.0 8.0:11.3 11.3:13.8 45.5:47.0 52.9:56.3 60.5:64.0"
fi

python3 -I make_layers.py layers "$LANG_CODE" >/dev/null

# Piece lengths, then the caption switch times and total length.
set -- $CUTS
LEN=()
SEGS=""
i=0
for c in "$@"; do
  a=${c%:*}; b=${c#*:}
  SEGS="${SEGS}[s$i]trim=$a:$b,setpts=PTS-STARTPTS[v$i];"
  LEN[$i]=$(echo "$b - $a" | bc)
  i=$((i+1))
done
T1=${LEN[0]}
T2=$(echo "${LEN[0]} + ${LEN[1]} + ${LEN[2]}" | bc)
T3=$(echo "$T2 + ${LEN[3]} + ${LEN[4]}" | bc)
TOTAL=$(echo "$T3 + ${LEN[5]}" | bc)

CAP="[3:v]format=rgba,fade=t=in:st=0:d=0.3:alpha=1[c0];[4:v]format=rgba,fade=t=in:st=$T1:d=0.3:alpha=1[c1];[5:v]format=rgba,fade=t=in:st=$T2:d=0.3:alpha=1[c2];[6:v]format=rgba,fade=t=in:st=$T3:d=0.3:alpha=1[c3]"

ffmpeg -hide_banner -loglevel error -y \
  -i "$TAKE" \
  -loop 1 -t "$TOTAL" -i layers/bg.png \
  -loop 1 -t "$TOTAL" -i layers/mask.png \
  -loop 1 -t "$TOTAL" -i layers/cap0.png \
  -loop 1 -t "$TOTAL" -i layers/cap1.png \
  -loop 1 -t "$TOTAL" -i layers/cap2.png \
  -loop 1 -t "$TOTAL" -i layers/cap3.png \
  -f lavfi -t "$TOTAL" -i anullsrc=r=44100:cl=stereo \
  -filter_complex "[0:v]fps=30,split=6[s0][s1][s2][s3][s4][s5];${SEGS}[v0][v1][v2][v3][v4][v5]concat=n=6:v=1:a=0,scale=678:1473:flags=lanczos,format=rgba[scr];[2:v]format=gray,fps=30[m];[scr][m]alphamerge[rounded];[1:v]fps=30,format=rgba[bg];[bg][rounded]overlay=104:409:shortest=1[b1];${CAP};[b1][c0]overlay=0:0:enable='lt(t,$T1)'[b2];[b2][c1]overlay=0:0:enable='between(t,$T1,$T2)'[b3];[b3][c2]overlay=0:0:enable='between(t,$T2,$T3)'[b4];[b4][c3]overlay=0:0:enable='gte(t,$T3)',format=yuv420p[v]" \
  -map "[v]" -map 7:a -t "$TOTAL" -r 30 \
  -c:v libx264 -profile:v high -preset slow -crf 16 -c:a aac -b:a 256k -movflags +faststart \
  "$OUT"
echo "$OUT: ${TOTAL}s, captions switch at ${T1}s, ${T2}s, ${T3}s"
