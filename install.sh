#!/bin/bash
# ==========================================
# Auto-Script Installer Z-Tunnel UDP Password
# OS Support: Ubuntu 20.04 / 22.04 / Debian 11
# ==========================================

clear
echo "========================================="
echo "   STARTING Z-TUNNEL UDP PASSWORD BUILD  "
echo "========================================="
sleep 2

# 1. Update Paket Sistem & Install Dependencies
echo "[+] Memperbarui paket sistem dan modul..."
apt update && apt upgrade -y
apt install git curl wget unzip nano golang cron -y

# 2. Membuat Direktori Kerja dan Database Lokal
mkdir -p /etc/z-tunnel
mkdir -p /var/lib/zivpn
touch /var/lib/zivpn/passwords.txt

# Mendapatkan IP VPS sebagai domain default awal
vps_ip=$(curl -s ipinfo.io/ip)
echo "$vps_ip" > /etc/z-tunnel/domain

# 3. Proses Cloning dan Kompilasi Core ZiVPN Bawaan GitHub
echo "[+] Cloning source code ZiVPN..."
rm -rf /root/zivpn-udp
git clone https://github.com/potatonc/zivpn-udp.git /root/zivpn-udp

echo "[+] Memulai proses kompilasi biner asli..."
cd /root/zivpn-udp
go build -o zivpn-server
mv zivpn-server /usr/bin/zivpn-server
chmod +x /usr/bin/zivpn-server

# Pembersihan file compiler agar VPS tetap ringan dan RAM lega
rm -rf /root/zivpn-udp
apt remove golang -y && apt autoremove -y

# 4. Membuat File Konfigurasi Awal
# Menggunakan sistem autentikasi eksternal berbasis file teks passwords.txt
mkdir -p /etc/zivpn
cat <<EOF > /etc/zivpn/config.json
{
    "server_port": "5600",
    "auth_type": "file",
    "auth_file": "/var/lib/zivpn/passwords.txt",
    "banner": "⚡ Z-TUNNEL PREMIUM PURE UDP ⚡"
}
EOF

# 5. Mendaftarkan ke Systemd Service (Auto-Run di Latar Belakang)
cat <<EOF > /etc/systemd/system/zivpn.service
[Unit]
Description=ZiVPN UDP Password Service
After=network.target

[Service]
User=root
Type=simple
ExecStart=/usr/bin/zivpn-server -config /etc/zivpn/config.json
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable zivpn
systemctl start zivpn

# 6. Mendaftarkan Auto-Clean Expired Akun Setiap Hari via Cron
cat <<EOF > /etc/cron.daily/zivpn-cleaner
#!/bin/bash
vps_time=\$(date +%s)
touch /var/lib/zivpn/passwords.txt.tmp
while IFS=' | ' read -r pass exp; do
    if [[ -n "\$exp" ]]; then
        exp_sec=\$(date -d "\$exp" +%s 2>/dev/null)
        if [[ \$vps_time -le \$exp_sec ]]; then
            echo "\$pass | \$exp" >> /var/lib/zivpn/passwords.txt.tmp
        fi
    else
        echo "\$pass" >> /var/lib/zivpn/passwords.txt.tmp
    fi
done < /var/lib/zivpn/passwords.txt
mv /var/lib/zivpn/passwords.txt.tmp /var/lib/zivpn/passwords.txt
systemctl restart zivpn
EOF
chmod +x /etc/cron.daily/zivpn-cleaner
systemctl restart cron

echo "========================================="
echo "   INSTALL SELESAI! SILAKAN PASANG MENU  "
echo "========================================="
