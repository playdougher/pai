#!/data/data/com.termux/files/usr/bin/sh
# Termux:Boot 开机自启脚本。安装 Termux:Boot app（与 Termux 同一签名来源，
# 装后手动打开一次），把本文件放到 ~/.termux/boot/pai.sh 并 chmod +x。
# PI_WEB_TITLE_SUFFIX 用来在浏览器标签里区分节点，按需改名。
termux-wake-lock
cd ~/pai
# Boot 脚本由非交互 sh 启动，不会自动读 .bashrc；API key 等环境变量
# 都在里面，不加载会导致 "No API key found" / 模型列表为空。
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
PI_WEB_NO_OPEN=1 PI_WEB_TITLE_SUFFIX=ph_ace5pro exec node bin/pi-web.js
