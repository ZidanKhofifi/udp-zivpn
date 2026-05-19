#!/bin/bash

clear
echo "========================================="
echo "     MEMULAI UPDATE SCRIPT Z-TUNNEL      "
echo "========================================="
sleep 1

echo "[*] Mengunduh pembaruan menu dari GitHub..."
curl -sL "https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/menu.sh" -o /usr/bin/menu.sh
chmod +x /usr/bin/menu.sh

echo "========================================="
echo "    UPDATE SELESAI! MEMBUKA MENU...     "
echo "========================================="
sleep 1
bash /usr/bin/menu.sh
