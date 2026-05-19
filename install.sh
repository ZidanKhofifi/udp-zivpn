#!/bin/bash

clear
echo "========================================="
echo "   INSTALLING Z-TUNNEL UDP NATIVE CORE   "
echo "========================================="
sleep 1

# 1. Install Dependencies Dasar
apt-get update -y
apt-get install curl wget shuf libc6 -y

# 2. Ambil Biner Asli Dari Zahidbd2 (Arsitektur AMD64/x86_64)
echo "[*] Mengunduh biner asli ZiVPN Server dari core source..."
mkdir -p /etc/zivpn
mkdir -p /var/lib/zivpn
wget -q -O /usr/bin/zivpn "https://raw.githubusercontent.com/zahidbd2/udp-zivpn/main/zivpn"
chmod +x /usr/bin/zivpn

# 3. Buat Konfigurasi Default config.json
cat <<EOF > /etc/zivpn/config.json
{
  "TunnelPort": 5600,
  "PasswordFile": "/var/lib/zivpn/passwords.txt",
  "Banner": "Welcome to Z-Tunnel UDP Service"
}
EOF

# 4. Buat Systemd Service File untuk ZiVPN
cat <<EOF > /etc/systemd/system/zivpn.service
[Unit]
Description=ZiVPN UDP Server Native Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/zivpn
ExecStart=/usr/bin/zivpn -config /etc/zivpn/config.json
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Jalankan Service Biner
systemctl daemon-reload
systemctl enable zivpn
systemctl start zivpn

# 5. Buat Skrip Otomatis Pembersih Akun Expired Harian (Cron Job)
cat <<'EOF' > /etc/cron.daily/zivpn-cleaner
#!/bin/bash
DB_FILE="/etc/z-tunnel/database.db"
ZIVPN_PASS_FILE="/var/lib/zivpn/passwords.txt"
today=$(date +%Y-%m-%d)

if [ -f "$DB_FILE" ]; then
    # Hapus baris yang tanggal expirednya kurang dari hari ini
    awk -v t="$today" -F'|' '$3 >= t {print $0}' "$DB_FILE" > "${DB_FILE}.tmp" && mv "${DB_FILE}.tmp" "$DB_FILE"
    # Tulis ulang password aktif ke biner
    awk -F'|' '{print $1}' "$DB_FILE" > "$ZIVPN_PASS_FILE"
    systemctl restart zivpn >/dev/null 2>&1
fi
EOF
chmod +x /etc/cron.daily/zivpn-cleaner

# 6. Konfigurasi Auto-Run Menu Saat Login VPS
if [ -f /usr/bin/menu.sh ]; then
    chmod +x /usr/bin/menu.sh
    sed -i '/menu.sh/d' ~/.bashrc
    echo '[[ -f /usr/bin/menu.sh ]] && bash /usr/bin/menu.sh' >> ~/.bashrc
    
    echo "========================================="
    echo "   INSTALL SELESAI! MEMBUKA MENU...      "
    echo "========================================="
    sleep 2
    bash /usr/bin/menu.sh
else
    echo "Skrip install selesai, pastikan file menu.sh sudah ditaruh di /usr/bin/"
fi
