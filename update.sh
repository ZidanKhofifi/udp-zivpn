#!/bin/bash

clear
echo "========================================="
echo "     MEMULAI UPDATE SCRIPT Z-TUNNEL      "
echo "========================================="
sleep 1

echo "[*] Mengunduh pembaruan menu dari GitHub..."
# Mengunduh file menu.sh terbaru dan langsung menimpa file lama di /usr/bin/
wget -q -O /usr/bin/menu.sh "https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/menu.sh"

# Memberikan kembali izin akses eksekusi
chmod +x /usr/bin/menu.sh

echo "========================================="
echo "    UPDATE SELESAI! MEMBUKA MENU...     "
echo "========================================="
sleep 1
bash /usr/bin/menu.sh
