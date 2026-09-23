#!/usr/bin/env bash
# 服务器直跑模式：在这台服务器上起一个带 CDP 调试端口的 Chrome
# —— 不需要家里那台电脑，也不需要任何隧道
#
# 适用：你有一台"IP 落在需要的地域"的服务器，且不想常开一台家用电脑
set -euo pipefail

PORT="${CDP_PORT:-9222}"
PROFILE="${CHROME_PROFILE:-$HOME/.cloudbrowser-chrome}"

echo "[1/3] 检查 Chrome ..."
if ! command -v google-chrome >/dev/null 2>&1; then
  echo "      没装，开始安装（Debian/Ubuntu）"
  tmp="$(mktemp -d)"
  wget -q -O "$tmp/chrome.deb" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo apt-get update -qq && sudo apt-get install -y "$tmp/chrome.deb"
  rm -rf "$tmp"
else
  echo "      已安装：$(command -v google-chrome)"
fi

echo "[2/3] 启动 Chrome（端口 $PORT，profile $PROFILE）"
mkdir -p "$PROFILE"
nohup google-chrome \
  --headless=new \
  --remote-debugging-port="$PORT" \
  --remote-debugging-address=127.0.0.1 \
  --user-data-dir="$PROFILE" \
  --no-first-run --no-default-browser-check --disable-gpu \
  >/dev/null 2>&1 &
sleep 4

echo "[3/3] 验证"
curl -s "http://127.0.0.1:$PORT/json/version" | head -c 200; echo
echo
echo "OK。自动化侧直接连 http://127.0.0.1:$PORT（见 ../server/cdp-bridge-example.js）"
