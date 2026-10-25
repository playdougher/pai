#!/bin/sh
# 构建并把运行时产物发布为 GitHub Release，供手机等设备免 build 拉取。
# 产物 = .next（不含 cache/dev/trace）。每个版本一个 Release，tag 形如
# prebuilt-<日期>-<源码短hash>，手机侧取 /releases/latest 即可。
# 用法: scripts/push-prebuilt.sh
set -e
repo=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo"

TOKEN=$(printf "protocol=https\nhost=github.com\n" \
  | git credential fill 2>/dev/null | grep '^password=' | cut -d= -f2-)
[ -n "$TOKEN" ] || { echo "no github token in credential store" >&2; exit 1; }
api() { curl -s -H "Authorization: token $TOKEN" "$@"; }

echo "==> npm run build"
npm run build

sha=$(git rev-parse --short HEAD)
tag="prebuilt-$(date +%Y%m%d-%H%M)-$sha"
name="Prebuilt $sha $(date +%F-%H:%M)"

echo "==> packing runtime artifacts"
tar -C . --exclude .next/cache --exclude .next/dev --exclude .next/trace \
  -czf "/tmp/pai-next-$tag.tar.gz" .next
size=$(du -h "/tmp/pai-next-$tag.tar.gz" | cut -f1)

echo "==> creating release $tag"
release=$(api -X POST https://api.github.com/repos/playdougher/pai/releases \
  -d "{\"tag_name\":\"$tag\",\"name\":\"$name\",\"body\":\"Built from $sha\",\"prerelease\":false}")
upload_url=$(printf "%s" "$release" | python3 -c "import json,sys; print(json.load(sys.stdin)['upload_url'].split('{')[0])")
[ -n "$upload_url" ] || { printf "%s\n" "$release" >&2; exit 1; }

echo "==> uploading tarball ($size)"
api -X POST -H "Content-Type: application/gzip" \
  --data-binary "@/tmp/pai-next-$tag.tar.gz" \
  "$upload_url?name=pai-next.tar.gz" >/dev/null
rm -f "/tmp/pai-next-$tag.tar.gz"
echo "==> done: https://github.com/playdougher/pai/releases/tag/$tag"

# 本机 pai 服务如果跑的就是这份工作区，重建 .next 后需要重启才能稳定服务
if systemctl --user is-active --quiet pai.service; then
  systemctl --user restart pai.service
  echo "==> restarted pai.service"
fi
