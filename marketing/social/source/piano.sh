#!/bin/bash
# Puts the piano recording (Bach, Prelude in C, played by LJ's piano teacher) under an
# Elapsa social video, instead of music.py's synthesised track.
#
#   piano.sh <en|zh> <output.mp4> [piano file]
#
# Needs social-<lang>/silent.mp4 from social.sh. Takes the piano from just after its
# opening silence, cleans it (low cut, light noise reduction), brings it to -16 LUFS,
# fades in over 0.3 s and out over the last 2 s. No chimes: they clash with a real piano.
set -e
cd "$(dirname "$0")"
LANG_CODE="$1"
OUT="$2"
PIANO="${3:-/Volumes/APPS/story/music/fast 2-44.mp3}"
VIDEO="social-$LANG_CODE/silent.mp4"
START=0.43
LEN=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$VIDEO")
FADE_OUT=$(echo "$LEN - 2" | bc)

ffmpeg -hide_banner -loglevel error -y -i "$VIDEO" -ss "$START" -t "$LEN" -i "$PIANO" \
  -filter_complex "[1:a]highpass=f=60,afftdn=nf=-55,acompressor=threshold=-28dB:ratio=2.5:attack=20:release=250,loudnorm=I=-16:LRA=7:TP=-1.5,afade=t=in:st=0:d=0.3,afade=t=out:st=$FADE_OUT:d=2,aresample=44100[a]" \
  -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 192k -shortest -movflags +faststart "$OUT"
echo "$OUT: ${LEN}s with piano"
