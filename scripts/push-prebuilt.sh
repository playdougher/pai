#!/bin/sh
# 构建并把 .next（不含 cache/dev 等运行时不需要的产物）推到 origin 的
# prebuilt 分支，供手机等设备免 build 拉取。
# 用法: scripts/push-prebuilt.sh [commit-message]
set -e
repo=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo"

echo "==> npm run build"
npm run build

msg="prebuilt $(git rev-parse --short HEAD) $(date +%F-%H%M) ${1:-}"

# 用独立 worktree 管理 prebuilt 孤儿分支，不动主工作区
wt=/tmp/pai-prebuilt-wt
rm -rf "$wt"
git worktree prune
if git show-ref --verify --quiet refs/remotes/origin/prebuilt; then
  git worktree add -B prebuilt "$wt" origin/prebuilt
elif git show-ref --verify --quiet refs/heads/prebuilt; then
  git worktree add "$wt" prebuilt
else
  git worktree add --orphan -b prebuilt "$wt"
fi

mkdir -p "$wt/.next"
rsync -a --delete \
  --exclude cache --exclude dev --exclude trace \
  .next/ "$wt/.next/"

cd "$wt"
git add -Af .next
if git diff --cached --quiet; then
  echo "==> no changes to prebuilt artifacts"
else
  git commit -q -m "$msg"
  git push -q origin prebuilt
  echo "==> pushed: $(git log --oneline -1)"
fi

# 本机 pai 服务如果跑的就是这份工作区，重建 .next 后需要重启才能稳定服务
if systemctl --user is-active --quiet pai.service; then
  systemctl --user restart pai.service
  echo "==> restarted pai.service"
fi
