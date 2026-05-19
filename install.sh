#!/bin/bash

clear
echo "========================================="
echo "    PREPARING MODIFIED POTATO SYSTEM     "
echo "========================================="
sleep 1

# 1. Bersihkan sisa-sisa file lama di VPS agar tidak bentrok
rm -f /usr/local/bin/zi.sh /usr/bin/menu.sh /usr/local/bin/zivpn

# 2. Mengunduh skrip inti (zi.sh) dan skrip tampilan (menu.sh) dari GitHub
echo "[*] Mengunduh skrip modifikasi terintegrasi..."
wget -q --no-cache -O /usr/local/bin/zi.sh "https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/zi.sh"
wget -q --no-cache -O /usr/bin/menu.sh "https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/menu.sh"

# 3. Memberikan izin eksekusi pada file yang sudah diunduh
chmod +x /usr/local/bin/zi.sh /usr/bin/menu.sh

# 4. Menjalankan fungsi instalasi biner yang ada di dalam zi.sh
bash /usr/local/bin/zi.sh install

# 5. Mengatur agar menu otomatis terbuka setiap kali login SSH/VPS
sed -i '/menu.sh/d' ~/.bashrc
echo '[[ -f /usr/bin/menu.sh ]] && bash /usr/bin/menu.sh' >> ~/.bashrc

echo "========================================="
echo "       SYSTEM READY! OPENING MENU...     "
echo "========================================="
sleep 1
bash /usr/bin/menu.sh
