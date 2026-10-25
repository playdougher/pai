#!/data/data/com.termux/files/usr/bin/sh
# 拉取最新 GitHub Release 的 prebuilt 产物并重启 pai。在源码 clone（~/pai）
# 里运行，无需本地构建。走 http_proxy/https_proxy 环境变量，若未设置则默认
# 走 192.168.10.130:7890。
set -e
cd ~/pai
export http_proxy="${http_proxy:-http://192.168.10.130:7890}"
export https_proxy="${https_proxy:-http://192.168.10.130:7890}"
url=$(curl -s https://api.github.com/repos/playdougher/pai/releases/latest \
  | python3 -c "import json,sys; print([a[\"browser_download_url\"] for a in json.load(sys.stdin)[\"assets\"] if a[\"name\"]==\"pai-next.tar.gz\"][0])")
echo "downloading $url"
curl -sL --max-time 600 -o ~/pai-next.tar.gz "$url"
rm -rf .next && tar xzf ~/pai-next.tar.gz -C ~/pai && rm ~/pai-next.tar.gz
pkill -f "bin/[p]i-web.js" || true
sleep 2
nohup ~/.termux/boot/pai.sh >/dev/null 2>&1 &
sleep 12
curl -s -o /dev/null -w "pai: HTTP %{http_code}\n" http://127.0.0.1:30141/
curl -s http://127.0.0.1:30141/api/pai-title; echo
