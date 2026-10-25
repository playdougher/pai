#!/data/data/com.termux/files/usr/bin/sh
# Termux:Boot 开机自启脚本。安装 Termux:Boot app（与 Termux 同一签名来源，
# 装后手动打开一次），把本文件放到 ~/.termux/boot/pai.sh 并 chmod +x。
termux-wake-lock
cd ~/pai
# Boot 脚本由非交互 sh 启动，不会自动读 .bashrc；API key 等环境变量
# 都在里面，不加载会导致 "No API key found" / 模型列表为空。
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"

# 浏览器标签后缀，用于多节点并排时区分（空字符串 = 不加后缀）
PI_WEB_TITLE_SUFFIX=ph_ace5pro

# 服务绑定地址。默认 127.0.0.1（仅本机访问）；改成设备内网 IP
# （如 10.77.0.4）可让局域网/VPN 内其他设备访问，但本机浏览器也需改用该 IP。
# 绑 0.0.0.0 则对所有接口开放，请只在可信网络使用。
PI_WEB_HOSTNAME=""

PI_WEB_NO_OPEN=1 exec node bin/pi-web.js
