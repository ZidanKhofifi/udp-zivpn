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

# Fungsi Sinkronisasi: Merakit ulang config.json dalam format Array JSON dengan Unix Epoch
sync_to_zivpn_json() {
    today_epoch=$(date +%s)
    
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
    while IFS='|' read -r pass duration exp; do
        if [[ -n "$pass" && -n "$exp" && "$exp" -ge "$today_epoch" ]]; then
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
  
  # Hapus komponen API jika ada
  systemctl stop z-api 2>/dev/null
  systemctl disable z-api 2>/dev/null
  rm -f /etc/systemd/system/z-api.service
  rm -rf /etc/z-api
  rm -rf "$DB_DIR"
  rm -f /etc/cron.d/zivpn-cleaner
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
    
    # Daftarkan pembersih otomatis menit kustom (Cron Job setiap menit)
    echo "* * * * * root bash /usr/local/bin/zi.sh clean >/dev/null 2>&1" > /etc/cron.d/zivpn-cleaner
    chmod 644 /etc/cron.d/zivpn-cleaner
    systemctl restart cron >/dev/null 2>&1
    
    echo -e "\n➜ ZIVPN UDP Potato Engine Berhasil Terpasang!\n"
  else
    echo -e "\n➜ Gagal mengaktifkan servis ZiVPN.\n"
    Uninstall
  fi
}

SetupAPI() {
    echo -e "\n========================================="
    echo -e "       KONFIGURASI API GATEWAY BOT       "
    echo -e "========================================="
    read -p " Masukkan API Key Rahasia Anda: " USER_KEY
    if [ -z "$USER_KEY" ]; then
        echo -e "\n➜ Error: API Key tidak boleh kosong!\n"
        exit 1
    fi

    echo "[*] Memeriksa komponen Node.js..."
    if ! command -v node &> /dev/null; then
        echo "[*] Menginstal Node.js dan npm..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash - &>/dev/null
        apt-get install -y nodejs &>/dev/null
    fi

    mkdir -p /etc/z-api
    cd /etc/z-api
    echo "[*] Memasang library pendukung (Express)..."
    npm init -y &>/dev/null
    npm install express &>/dev/null

    echo "[*] Membuat berkas server backend..."
    cat > server.js <<EOF
const express = require('express');
const { exec } = require('child_process');
const app = express();
const PORT = 3000;
const SECRET_KEY = "$USER_KEY";

app.use(express.json());

const authenticate = (req, res, next) => {
    const apiKey = req.headers['x-api-key'];
    if (apiKey && apiKey === SECRET_KEY) {
        next();
    } else {
        res.status(401).json({ status: false, message: 'Unauthorized' });
    }
};

app.get('/list', authenticate, (req, res) => {
    exec('bash /usr/local/bin/zi.sh list', (err, stdout) => {
        if (err) return res.status(500).json({ status: false, message: 'Gagal ambil data' });
        return res.json({ status: true, output: stdout });
    });
});

app.post('/account', authenticate, (req, res) => {
    const { type, password, days, minutes } = req.body;
    if (type === 'trial') {
        const trialMinutes = minutes || 30;
        exec(\`bash /usr/local/bin/zi.sh trial "\${trialMinutes}"\`, (err, stdout) => {
            if (err) return res.status(500).json({ status: false, error: err.message });
            return res.json({ status: true, message: 'Trial Created', output: stdout });
        });
    } else if (type === 'premium') {
        if (!password || !days) return res.status(400).json({ status: false, message: 'Missing parameters' });
        exec(\`bash /usr/local/bin/zi.sh add "\${password}" "\${days}"\`, (err, stdout) => {
            if (err) return res.status(500).json({ status: false, error: err.message });
            return res.json({ status: true, message: 'Premium Created', output: stdout });
        });
    } else {
        res.status(400).json({ status: false, message: 'Invalid type' });
    }
});

app.delete('/account', authenticate, (req, res) => {
    const { password } = req.body;
    if (!password) return res.status(400).json({ status: false, message: 'Missing password' });
    exec(\`bash /usr/local/bin/zi.sh del "\${password}"\`, (err, stdout) => {
        if (err) return res.status(500).json({ status: false, error: err.message });
        return res.json({ status: true, message: 'Account Deleted', output: stdout });
    });
});

app.listen(PORT);
EOF

    cat > /etc/systemd/system/z-api.service <<-END
[Unit]
Description=API Gateway Z-Tunnel
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/z-api
ExecStart=/usr/bin/node server.js
Restart=always

[Install]
WantedBy=multi-user.target
END

    systemctl daemon-reload
    systemctl enable z-api &>/dev/null
    systemctl start z-api
    
    echo -e "\n========================================="
    echo -e "       API GATEWAY BERHASIL AKTIF        "
    echo -e "========================================="
    echo -e " URL API  : http://$(wget -qO- icanhazip.com):3000"
    echo -e " API Key  : $USER_KEY"
    echo -e "=========================================\n"
}

case "$1" in
  'install') Install ;;
  'uninstall') Uninstall; echo -e "\n➜ Bersih total.\n" ;;
  'api') SetupAPI ;;
  'add')
    PREMIUM_PASS="$2"
    PREMIUM_DAYS="$3"
    
    if [[ -z "$PREMIUM_PASS" || -z "$PREMIUM_DAYS" ]]; then
        echo -e "\n========================================="
        echo -e "           BUAT AKUN PREMIUM             "
        echo -e "========================================="
        read -p " Masukkan Password : " PREMIUM_PASS
        read -p " Masukkan Masa Aktif (Hari): " PREMIUM_DAYS
    fi
    
    if [[ -z "$PREMIUM_PASS" || -z "$PREMIUM_DAYS" || ! "$PREMIUM_DAYS" =~ ^[0-9]+$ ]]; then
        echo -e "\n➜ Error: Input tidak valid!\n"
        exit 1
    fi
    if grep -q "^$PREMIUM_PASS|" "$DB_FILE"; then
        echo -e "\n➜ Error: Password sudah ada!\n"
        exit 1
    fi
    
    exp_date=$(date -d "+$PREMIUM_DAYS days" +%s)
    readable_exp=$(date -d "@$exp_date" "+%Y-%m-%d %H:%M:%S")
    echo "$PREMIUM_PASS|$PREMIUM_DAYS|$exp_date" >> "$DB_FILE"
    sync_to_zivpn_json
    
    echo -e "\n========================================="
    echo -e "      SUKSES MEMBUAT AKUN PREMIUM        "
    echo -e "========================================="
    echo -e " Host/Domain: $CURRENT_DOMAIN"
    echo -e " Password   : $PREMIUM_PASS"
    echo -e " Masa Aktif : $PREMIUM_DAYS Hari"
    echo -e " Expired On : $readable_exp"
    echo -e " Port Range : 6000 - 19999 (UDP)"
    echo -e "=========================================\n"
    ;;
    
  'trial')
    TRIAL_MINUTES="$2"
    
    if [[ -z "$TRIAL_MINUTES" ]]; then
        echo -e "\n========================================="
        echo -e "           BUAT AKUN TRIAL               "
        echo -e "========================================="
        read -p " Masukkan Durasi (Menit): " TRIAL_MINUTES
    fi
    
    if [[ -z "$TRIAL_MINUTES" || ! "$TRIAL_MINUTES" =~ ^[0-9]+$ ]]; then
        TRIAL_MINUTES=30
    fi
    
    TRIAL_PASS=$(shuf -i 100000-999999 -n 1)
    exp_date=$(date -d "+$TRIAL_MINUTES minutes" +%s)
    readable_exp=$(date -d "@$exp_date" "+%Y-%m-%d %H:%M:%S")
    echo "$TRIAL_PASS|$TRIAL_MINUTES|$exp_date" >> "$DB_FILE"
    sync_to_zivpn_json
    
    echo -e "\n========================================="
    echo -e "      SUKSES MEMBUAT AKUN TRIAL          "
    echo -e "========================================="
    echo -e " Host/Domain: $CURRENT_DOMAIN"
    echo -e " Password   : $TRIAL_PASS"
    echo -e " Masa Aktif : $TRIAL_MINUTES Menit"
    echo -e " Expired On : $readable_exp"
    echo -e " Port Range : 6000 - 19999 (UDP)"
    echo -e "=========================================\n"
    ;;
    
  'del')
    DEL_PASS="$2"
    
    if [[ -z "$DEL_PASS" ]]; then
        echo -e "\n========================================="
        echo -e "             HAPUS AKUN UDP              "
        echo -e "========================================="
        read -p " Masukkan password yang ingin dihapus: " DEL_PASS
    fi
    
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
    printf "%-15s | %-12s | %-19s\n" "PASSWORD" "DURASI" "TANGGAL EXPIRED"
    echo "-----------------------------------------------------"
    today_epoch=$(date +%s)
    while IFS='|' read -r pass duration exp; do
        if [[ -n "$pass" ]]; then
            readable_exp=$(date -d "@$exp" "+%Y-%m-%d %H:%M:%S")
            if [[ "$exp" -lt "$today_epoch" ]]; then
                printf "%-15s | %-12s | %-19s \033[0;31m(Expired)\033[0m\n" "$pass" "$duration" "$readable_exp"
            else
                printf "%-15s | %-12s | %-19s \033[0;32m(Aktif)\033[0m\n" "$pass" "$duration" "$readable_exp"
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

  'clean')
    today_epoch=$(date +%s)
    if [ -f "$DB_FILE" ]; then
        touch "${DB_FILE}.tmp"
        while IFS='|' read -r pass duration exp; do
            if [[ -n "$pass" && -n "$exp" && "$exp" -ge "$today_epoch" ]]; then
                echo "$pass|$duration|$exp" >> "${DB_FILE}.tmp"
            fi
        done < "$DB_FILE"
        mv "${DB_FILE}.tmp" "$DB_FILE"
        sync_to_zivpn_json
    fi
    ;;
    
  *)
    echo -e "\n Gunakan perintah: zi.sh [install|uninstall|api|add|trial|del|list|domain|backup|restore|clean]\n"
    ;;
esac
