#!/bin/bash
# 승률 엔진 — 로컬 런처
#   그냥 실행:      Finder 에서 더블클릭
#   휴대폰에서도:   터미널에서  ./launch.command --lan
set -u
cd "$(dirname "$0")"

FILE="index.html"
if [ ! -f "$FILE" ]; then
  echo "❌ $FILE 을 찾을 수 없습니다. 이 스크립트를 index.html 과 같은 폴더에 두세요."
  read -r -p "엔터를 누르면 닫힙니다..." _
  exit 1
fi

# 파이썬이 없으면 파일을 그냥 연다. 페이지가 완전히 자족적이라 file:// 로도 동작한다.
if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 이 없어 파일을 직접 엽니다 (기능은 동일합니다)."
  open "$FILE"
  exit 0
fi

BIND="127.0.0.1"
LAN=0
if [ "${1:-}" = "--lan" ]; then BIND="0.0.0.0"; LAN=1; fi

PORT=8777
while lsof -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; do
  PORT=$((PORT + 1))
  [ "$PORT" -gt 8800 ] && { echo "❌ 빈 포트를 찾지 못했습니다."; exit 1; }
done

python3 -m http.server "$PORT" --bind "$BIND" >/dev/null 2>&1 &
SRV=$!
cleanup(){ kill "$SRV" 2>/dev/null; echo; echo "서버를 껐습니다."; }
trap cleanup EXIT INT TERM

sleep 0.7
if ! kill -0 "$SRV" 2>/dev/null; then
  echo "서버를 띄우지 못해 파일을 직접 엽니다."
  open "$FILE"
  exit 0
fi

URL="http://localhost:$PORT/$FILE"
echo "────────────────────────────────────────"
echo "  승률 엔진이 켜졌습니다"
echo "  이 컴퓨터:  $URL"
if [ "$LAN" = "1" ]; then
  IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)"
  if [ -n "$IP" ]; then
    echo "  같은 와이파이의 휴대폰:  http://$IP:$PORT/$FILE"
    echo "  ⚠ --lan 은 같은 네트워크의 다른 기기에 이 폴더를 열어 줍니다. 끝나면 Ctrl-C 로 끄세요."
  else
    echo "  (와이파이 주소를 찾지 못했습니다)"
  fi
else
  echo "  휴대폰에서도 열려면:  ./launch.command --lan"
fi
echo "  끄려면 Ctrl-C"
echo "────────────────────────────────────────"

open "$URL"
wait "$SRV"
