#!/bin/bash

clear
echo "========================================="
echo "   MEMULAI INSTALASI ENGINE Z-TUNNEL     "
echo "========================================="
sleep 1

# 1. Jalankan instalasi inti milik Potato secara otomatis
echo "[*] Mengunduh dan memasang biner ZiVPN Server..."
bash <(wget -qO- https://raw.githubusercontent.com/potatonc/zivpn-udp/refs/heads/main/zi.sh) install

# 2. Atur izin akses untuk menu manajemen utama
if [ -f /usr/bin/menu.sh ]; then
    chmod +x /usr/bin/menu.sh
    echo "========================================="
    echo "   INSTALL SELESAI! MEMBUKA MENU...      "
    echo "========================================="
    sleep 2
    bash /usr/bin/menu.sh
else
    echo "========================================="
    echo " INSTALL SELESAI! FILE menu.sh BELUM ADA "
    echo "========================================="
    echo "Silakan pastikan file menu.sh sudah ditaruh di /usr/bin/"
fi
