#!/bin/bash

clear
echo "========================================="
echo "   INSTALLING Z-TUNNEL NATIVE POTATO     "
echo "========================================="
sleep 1

# 1. Install Dependencies Dasar
apt-get update -y
apt-get install curl wget shuf libc6 -y

# 2. Ambil Biner Kompatibel dari Repositori Potato (Jalur Tradisional)
echo "[*] Mengunduh biner ZiVPN versi kompatibel..."
mkdir -p /etc/zivpn
mkdir -p /var/lib/zivpn
mkdir -p /etc/z-tunnel

# Membersihkan sisa file lama jika ada
rm -f /usr/bin/zivpn

# Menggunakan URL jalur pintas murni tanpa /refs/heads/
wget -q --no-cache -O /usr/bin/zivpn "https://raw.githubusercontent.com/potatonc/zivpn-udp/main/zivpn"

# Verifikasi apakah file berhasil diunduh dan tidak kosong
if [ ! -s /usr/bin/zivpn ] || [ $(wc -c < /usr/bin/zivpn) -lt 1000 ]; then
    echo "[!] Jalur utama gagal, mencoba jalur alternatif 2..."
    rm -f /usr/bin/zivpn
    curl -k -sL "https://raw.githubusercontent.com/potatonc/zivpn-udp/main/zivpn" -o /usr/bin/zivpn
fi

# Cek final sebelum memberi izin akses
if [ -s /usr/bin/zivpn ]; then
    chmod +x /usr/bin/zivpn
    echo "[+] Biner ZiVPN berhasil dipasang dengan aman."
else
    echo -e "\033[0;31m[-] GAGAL MENGUNDUH BINER ZIVPN! Proses dihentikan.\033[0m"
    exit 1
fi

# 3. Buat Konfigurasi Default config.json
cat <<EOF > /etc/zivpn/config.json
{
  "TunnelPort": 5600,
  "PasswordFile": "/var/lib/zivpn/passwords.txt",
  "Banner": "Welcome to Z-Tunnel UDP Service"
}
EOF

# 4. Siapkan File Database Password dengan Izin Penuh
touch /var/lib/zivpn/passwords.txt
chmod 777 /var/lib/zivpn/passwords.txt

# 5. Buat Systemd Service File untuk ZiVPN
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
systemctl restart zivpn

# 6. Buat Skrip Otomatis Pembersih Akun Expired Harian (Cron Job)
cat <<'EOF' > /etc/cron.daily/zivpn-cleaner
#!/bin/bash
DB_FILE="/etc/z-tunnel/database.db"
ZIVPN_PASS_FILE="/var/lib/zivpn/passwords.txt"
today=$(date +%Y-%m-%d)

if [ -f "$DB_FILE" ]; then
    awk -v t="$today" -F'|' '$3 >= t {print $0}' "$DB_FILE" > "${DB_FILE}.tmp" && mv "${DB_FILE}.tmp" "$DB_FILE"
    awk -F'|' '{print $1}' "$DB_FILE" > "$ZIVPN_PASS_FILE"
    chmod 777 "$ZIVPN_PASS_FILE"
    systemctl restart zivpn >/dev/null 2>&1
fi
EOF
chmod +x /etc/cron.daily/zivpn-cleaner

# 7. Konfigurasi Auto-Run Menu Saat Login VPS
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
