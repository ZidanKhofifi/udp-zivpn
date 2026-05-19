#!/bin/bash
# Zivpn UDP Module installer - Premium Modified Version
# Base Core Engine by Zahid Islam & Potato
# Modified by ZidanKhofifi

NIC=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
Sysctl="/etc/sysctl.conf"
FileSys="/etc/systemd/system/zivpn.service"
Dir="/etc/zivpn"
FileBackup="/root/config.json.zivpn"
MACHINE=

# Folder Database Tambahan
DB_DIR="/etc/z-tunnel"
DB_FILE="$DB_DIR/database.db"
DOMAIN_FILE="$DB_DIR/domain"

mkdir -p "$DB_DIR"
touch "$DB_FILE"
touch "$DOMAIN_FILE"

if [ ! -s "$DOMAIN_FILE" ]; then
    echo "Belum_Diatur" > "$DOMAIN_FILE"
fi
CURRENT_DOMAIN=$(cat "$DOMAIN_FILE")

RestartZivpn() {
  systemctl -q restart zivpn
}

Machine() {
  if [[ "$(uname)" == 'Linux' ]]; then
    case "$(uname -m)" in
      'amd64' | 'x86_64') MACHINE='amd64' ;;
      'armv5tel') MACHINE='arm' ;;
      'armv8' | 'aarch64') MACHINE='arm64' ;;
      *) echo -e "\n➜ error: Arsitektur ini tidak didukung.\n"; MACHINE='' ;;
    esac
  else
    echo -e "\n➜ error: Sistem operasi ini tidak didukung.\n"; MACHINE=''
  fi
}

AppendLine() {
  local file="$1"
  local text="$2"
  if ! grep -Fxq "$text" "$file"; then
    printf '%s\n' "$text" >> "$file"
    return 0
  fi
  return 1
}

Utils() {
  case "$1" in
    'rt') iptables -t nat -S PREROUTING | grep -w ":5667" >/dev/null 2>&1 ;;
    'cmd') command -v "$2" >/dev/null 2>&1 ;;
    'file') [ -f "$2" ] ;;
    'folder') [ -d "$2" ] ;;
    *) return 1 ;;
  esac
}

# Fungsi Sinkronisasi: Merakit ulang config.json dalam format Array JSON murni tanpa python
sync_to_zivpn_json() {
    today=$(date +%Y-%m-%d)
    
    cat <<EOF > "$Dir/config.json"
{
  "listen": ":5667",
  "cert": "$Dir/zivpn.crt",
  "key": "$Dir/zivpn.key",
  "obfs": "zivpn",
  "auth": {
    "mode": "passwords",
    "config": [
EOF

    first=true
    while IFS='|' read -r pass days exp; do
        if [[ -n "$pass" && "$exp" >= "$today" ]]; then
            if [ "$first" = true ]; then
                echo "      \"$pass\"" >> "$Dir/config.json"
                first=false
            else
                echo "      ,\"$pass\"" >> "$Dir/config.json"
            fi
        fi
    done < "$DB_FILE"

    cat <<EOF >> "$Dir/config.json"
    ]
  }
}
EOF
    RestartZivpn
}

Certificate() {
  echo
  openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=California/L=Los Angeles/O=Example Corp/OU=IT Department/CN=zivpn" -keyout "$Dir/zivpn.key" -out "$Dir/zivpn.crt"
  echo
}

PostKernel() {
  AppendLine "$Sysctl" "net.core.rmem_max=16777216"
  AppendLine "$Sysctl" "net.core.wmem_max=16777216"
  sysctl -w net.core.rmem_max=16777216 1> /dev/null 2> /dev/null
  sysctl -w net.core.wmem_max=16777216 1> /dev/null 2> /dev/null
}

RoutingTables() {
  if Utils rt; then
    iptables -t nat -D PREROUTING -i $NIC -p udp --dport 6000:19999 -j DNAT --to-destination :5667
  fi
  iptables -t nat -A PREROUTING -i $NIC -p udp --dport 6000:19999 -j DNAT --to-destination :5667
}

Uninstall() {
  if Utils file $FileSys; then
    systemctl -q stop zivpn
    systemctl -q disable zivpn
    rm -f $FileSys
  fi
  if Utils cmd zivpn; then
    killall zivpn 1> /dev/null 2> /dev/null
    rm -f /usr/local/bin/zivpn
  fi
  if Utils folder $Dir; then
    rm -rf $Dir
  fi
  if Utils rt; then
    iptables -t nat -D PREROUTING -i $NIC -p udp --dport 6000:19999 -j DNAT --to-destination :5667
  fi
  rm -rf "$DB_DIR"
}

Install() {
  Machine
  if [ -z "$MACHINE" ]; then
    exit 1
  fi
  
  if Utils file $FileSys; then
    systemctl -q stop zivpn
    systemctl -q disable zivpn
    rm -f $FileSys
  fi

  mkdir -p $Dir
  echo "[*] Mengunduh biner resmi ZiVPN v1.4.9 ($MACHINE)..."
  wget -q "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-$MACHINE" -O /usr/local/bin/zivpn
  chmod +x /usr/local/bin/zivpn
  
  Certificate
  sync_to_zivpn_json

  # Buat berkas Systemd Service
  cat > /etc/systemd/system/zivpn.service <<-END
[Unit]
Description=zivpn VPN Server Premium Mod
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$Dir
ExecStart=/usr/local/bin/zivpn server -c $Dir/config.json
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
END

  systemctl daemon-reload
  systemctl -q enable zivpn
  systemctl -q start zivpn
  
  if [[ $(systemctl is-active zivpn) == 'active' ]]; then
    PostKernel
    RoutingTables
    
    # Daftarkan pembersih otomatis harian (Cron Job harian)
    cat <<'EOF' > /etc/cron.daily/zivpn-cleaner
#!/bin/bash
DB_FILE="/etc/z-tunnel/database.db"
Dir="/etc/zivpn"
today=$(date +%Y-%m-%d)
if [ -f "$DB_FILE" ]; then
    awk -v t="$today" -F'|' '$3 >= t {print $0}' "$DB_FILE" > "${DB_FILE}.tmp" && mv "${DB_FILE}.tmp" "$DB_FILE"
    
    cat <<EOF2 > "$Dir/config.json"
{
  "listen": ":5667",
  "cert": "$Dir/zivpn.crt",
  "key": "$Dir/zivpn.key",
  "obfs": "zivpn",
  "auth": {
    "mode": "passwords",
    "config": [
EOF2
    first=true
    while IFS='|' read -r pass days exp; do
        if [[ -n "$pass" && "$exp" >= "$today" ]]; then
            if [ "$first" = true ]; then
                echo "      \"$pass\"" >> "$Dir/config.json"
                first=false
            else
                echo "      ,\"$pass\"" >> "$Dir/config.json"
            fi
        fi
    done < "$DB_FILE"
    cat <<EOF3 >> "$Dir/config.json"
    ]
  }
}
EOF3
    systemctl restart zivpn >/dev/null 2>&1
fi
EOF
    chmod +x /etc/cron.daily/zivpn-cleaner
    
    echo -e "\n➜ ZIVPN UDP Potato Engine Berhasil Terpasang!\n"
  else
    echo -e "\n➜ Gagal mengaktifkan servis ZiVPN.\n"
    Uninstall
  fi
}

case "$1" in
  'install') Install ;;
  'uninstall') Uninstall; echo -e "\n➜ Bersih total.\n" ;;
  'add')
    echo -e "\n========================================="
    echo -e "           BUAT AKUN PREMIUM             "
    echo -e "========================================="
    read -p " Masukkan Password : " PREMIUM_PASS
    read -p " Masukkan Masa Aktif (Hari): " PREMIUM_DAYS
    
    if [[ -z "$PREMIUM_PASS" || -z "$PREMIUM_DAYS" || ! "$PREMIUM_DAYS" =~ ^[0-9]+$ ]]; then
        echo -e "\n➜ Error: Input tidak valid!\n"
        exit 1
    fi
    if grep -q "^$PREMIUM_PASS|" "$DB_FILE"; then
        echo -e "\n➜ Error: Password sudah ada!\n"
        exit 1
    fi
    
    exp_date=$(date -d "+$PREMIUM_DAYS days" +%Y-%m-%d)
    echo "$PREMIUM_PASS|$PREMIUM_DAYS|$exp_date" >> "$DB_FILE"
    sync_to_zivpn_json
    
    echo -e "\n========================================="
    echo -e "      SUKSES MEMBUAT AKUN PREMIUM        "
    echo -e "========================================="
    echo -e " Host/Domain: $CURRENT_DOMAIN"
    echo -e " Password   : $PREMIUM_PASS"
    echo -e " Masa Aktif : $PREMIUM_DAYS Hari"
    echo -e " Expired On : $exp_date"
    echo -e " Port Range : 6000 - 19999 (UDP)"
    echo -e "=========================================\n"
    ;;
    
  'trial')
    TRIAL_PASS=$(shuf -i 100000-999999 -n 1)
    exp_date=$(date -d "+1 day" +%Y-%m-%d)
    echo "$TRIAL_PASS|1|$exp_date" >> "$DB_FILE"
    sync_to_zivpn_json
    
    echo -e "\n========================================="
    echo -e "      SUKSES MEMBUAT AKUN TRIAL          "
    echo -e "========================================="
    echo -e " Host/Domain: $CURRENT_DOMAIN"
    echo -e " Password   : $TRIAL_PASS"
    echo -e " Masa Aktif : 1 Hari"
    echo -e " Expired On : $exp_date"
    echo -e " Port Range : 6000 - 19999 (UDP)"
    echo -e "=========================================\n"
    ;;
    
  'del')
    echo -e "\n========================================="
    echo -e "             HAPUS AKUN UDP              "
    echo -e "========================================="
    read -p " Masukkan password yang ingin dihapus: " DEL_PASS
    if ! grep -q "^$DEL_PASS|" "$DB_FILE"; then
        echo -e "\n➜ Error: Password tidak ditemukan!\n"
        exit 1
    fi
    sed -i "/^$DEL_PASS|/d" "$DB_FILE"
    sync_to_zivpn_json
    echo -e "\n➜ Akun [$DEL_PASS] berhasil dihapus.\n"
    ;;
    
  'list')
    echo -e "\n====================================================="
    echo -e "               DAFTAR AKUN UDP ACTIVE                "
    echo -e "====================================================="
    printf "%-15s | %-12s | %-15s\n" "PASSWORD" "DURASI (HARI)" "TANGGAL EXPIRED"
    echo "-----------------------------------------------------"
    today=$(date +%Y-%m-%d)
    while IFS='|' read -r pass days exp; do
        if [[ -n "$pass" ]]; then
            if [[ "$exp" < "$today" ]]; then
                printf "%-15s | %-12s | %-15s \033[0;31m(Expired)\033[0m\n" "$pass" "$days" "$exp"
            else
                printf "%-15s | %-12s | %-15s \033[0;32m(Aktif)\033[0m\n" "$pass" "$days" "$exp"
            fi
        fi
    done < "$DB_FILE"
    echo -e "=====================================================\n"
    ;;
    
  'domain')
    echo -e "\nDomain Saat Ini: $CURRENT_DOMAIN"
    read -p " Masukkan Domain Baru: " NEW_DOMAIN
    if [ -n "$NEW_DOMAIN" ]; then
        echo "$NEW_DOMAIN" > "$DOMAIN_FILE"
        echo -e "\n➜ Domain diperbarui menjadi: $NEW_DOMAIN\n"
    fi
    ;;
    
  'backup')
    if [ -f "$DB_FILE" ]; then
        cp "$DB_FILE" "$FileBackup"
        cp "$DOMAIN_FILE" "${FileBackup}.domain"
        echo -e "\n➜ Cadangan disimpan di $FileBackup\n"
    else
        echo -e "\n➜ Database kosong.\n"
    fi
    ;;
    
  'restore')
    if [ -f "$FileBackup" ]; then
        cp "$FileBackup" "$DB_FILE"
        cp "${FileBackup}.domain" "$DOMAIN_FILE"
        sync_to_zivpn_json
        echo -e "\n➜ Berhasil memulihkan data cadangan.\n"
    else
        echo -e "\n➜ Berkas cadangan tidak ditemukan.\n"
    fi
    ;;
    
  *)
    echo -e "\n Gunakan perintah: zi.sh [install|uninstall|add|trial|del|list|domain|backup|restore]\n"
    ;;
esac
