#!/bin/bash
# Modul ZiVPN UDP - Versi Premium Modifikasi
# Mesin Inti oleh Zahid Islam & Potato
# Dimodifikasi oleh ZidanKhofifi

NIC=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
Sysctl="/etc/sysctl.conf"
FileSys="/etc/systemd/system/zivpn.service"
Dir="/etc/zivpn"
FileBackup="/root/config.json.zivpn"
MACHINE=""

# Direktori dan Berkas Database
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
  local arch_check=$(uname -m)
  if [[ "$arch_check" == 'Linux' || -n "$arch_check" ]]; then
    case "$arch_check" in
      'amd64' | 'x86_64') MACHINE='amd64' ;;
      'armv5tel') MACHINE='arm' ;;
      'armv8' | 'aarch64') MACHINE='arm64' ;;
      *) MACHINE='amd64' ;; # Default ke amd64 jika arsitektur tidak spesifik
    esac
  else
    MACHINE='amd64'
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

# Sinkronisasi Database ke Berkas Konfigurasi ZiVPN
sync_to_zivpn_json() {
    today_epoch=$(date +%s)
    
    mkdir -p "$Dir"
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
    MACHINE="amd64"
  fi
  
  if Utils file $FileSys; then
    systemctl -q stop zivpn
    systemctl -q disable zivpn
    rm -f $FileSys
  fi

  mkdir -p $Dir
  echo "[*] Mengunduh biner resmi ZiVPN v1.4.9 ($MACHINE)..."
  
  # Penghapusan file lama jika rusak sebelum mengunduh yang baru
  rm -f /usr/local/bin/zivpn
  wget -q --timeout=15 --tries=3 "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-$MACHINE" -O /usr/local/bin/zivpn
  
  # Validasi pengaman: Jika unduhan gagal, buat biner darurat atau pakai lokal biner cadangan
  if [ ! -s "/usr/local/bin/zivpn" ]; then
      echo "[-] Unduhan biner gagal, mencoba link alternatif..."
      wget -q "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64" -O /usr/local/bin/zivpn
  fi
  
  chmod +x /usr/local/bin/zivpn
  
  Certificate
  sync_to_zivpn_json

  # Konfigurasi Systemd Service ZiVPN dengan fitur Auto-Restart
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
    
    # Penjadwalan Pembersihan Akun Expired Setiap Menit
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
    read -p " Masukkan API Key Rahasia: " USER_KEY
    if [ -z "$USER_KEY" ]; then
        echo -e "\n➜ Error: API Key tidak boleh kosong!\n"
        exit 1
    fi

    echo "[*] Memeriksa komponen Node.js..."
    if ! command -v node &>/dev/null; then
        echo "[*] Menginstal Node.js dan npm..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash - &>/dev/null
        apt-get install -y nodejs &>/dev/null
    fi

    mkdir -p /etc/z-api
    cd /etc/z-api
    echo "[*] Memasang pustaka Express..."
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
        if (err) return res.status(500).json({ status: false, message: 'Gagal mengambil data' });
        return res.json({ status: true, output: stdout });
    });
});

app.get('/status', authenticate, (req, res) => {
    exec('bash /usr/local/bin/zi.sh status', (err, stdout) => {
        if (err) return res.status(500).json({ status: false, message: 'Gagal mengambil status' });
        const parts = stdout.trim().split('|');
        const zivpn = parts[0] ? parts[0].split(':')[1] : 'Inactive';
        const zapi = parts[1] ? parts[1].split(':')[1] : 'Inactive';
        return res.json({ status: true, zivpn, zapi });
    });
});

app.post('/restart', authenticate, (req, res) => {
    res.json({ status: true, message: 'Proses restart telah diinisialisasi' });
    
    exec('systemctl restart zivpn', (err) => {
        if (err) console.error('Gagal restart zivpn:', err.message);
    });

    setTimeout(() => {
        process.exit(0);
    }, 1000);
});

app.post('/update', authenticate, (req, res) => {
    exec('bash /usr/local/bin/zi.sh update', (err, stdout) => {
        if (err) return res.status(500).json({ status: false, message: 'Gagal melakukan pembaruan' });
        return res.json({ status: true, message: 'Pembaruan berhasil diselesaikan', output: stdout });
    });
});

app.post('/renew', authenticate, (req, res) => {
    const { password, days } = req.body;
    if (!password || !days) return res.status(400).json({ status: false, message: 'Parameter tidak lengkap' });
    exec(\`bash /usr/local/bin/zi.sh renew "\${password}" "\${days}"\`, (err, stdout) => {
        if (err) return res.status(500).json({ status: false, error: err.message });
        if (stdout.includes("Error") || stdout.includes("error") || stdout.includes("Gagal")) {
            return res.status(400).json({ status: false, error: stdout.trim() });
        }
        return res.json({ status: true, message: 'Account Renewed', output: stdout });
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
        if (!password || !days) return res.status(400).json({ status: false, message: 'Parameter tidak lengkap' });
        exec(\`bash /usr/local/bin/zi.sh add "\${password}" "\${days}"\`, (err, stdout) => {
            if (err) return res.status(500).json({ status: false, error: err.message });
            return res.json({ status: true, message: 'Premium Created', output: stdout });
        });
    } else {
        res.status(400).json({ status: false, message: 'Tipe akun tidak valid' });
    }
});

app.delete('/account', authenticate, (req, res) => {
    const { password } = req.body;
    if (!password) return res.status(400).json({ status: false, message: 'Password harus disertakan' });
    exec(\`bash /usr/local/bin/zi.sh del "\${password}"\`, (err, stdout) => {
        if (err) return res.status(500).json({ status: false, error: err.message });
        return res.json({ status: true, message: 'Account Deleted', output: stdout });
    });
});

app.post('/del-expired', authenticate, (req, res) => {
    exec('bash /usr/local/bin/zi.sh del-expired', (err, stdout) => {
        if (err) return res.status(500).json({ status: false, error: err.message });
        return res.json({ status: true, message: 'Expired Accounts Deleted', output: stdout });
    });
});

app.listen(PORT);
EOF

    # Konfigurasi Systemd Service API Gateway dengan fitur Auto-Restart
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
RestartSec=3

[Install]
WantedBy=multi-user.target
END

    systemctl daemon-reload
    systemctl enable z-api &>/dev/null
    systemctl restart z-api
    
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
        if [ -t 0 ]; then
            echo -e "\n========================================="
            echo -e "           BUAT AKUN PREMIUM             "
            echo -e "========================================="
            read -p " Masukkan Password : " PREMIUM_PASS
            read -p " Masukkan Masa Aktif (Hari): " PREMIUM_DAYS
        else
            echo "➜ Error: Argumen tidak lengkap untuk mode non-interaktif."
            exit 1
        fi
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
    echo "$PREMIUM_PASS|$PREMIUM_DAYS Hari|$exp_date" >> "$DB_FILE"
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
    
  'renew')
    RENEW_PASS="$2"
    RENEW_DAYS="$3"
    
    if [[ -z "$RENEW_PASS" || -z "$RENEW_DAYS" || ! "$RENEW_DAYS" =~ ^[0-9]+$ ]]; then
        echo -e "➜ Error: Parameter tidak valid."
        exit 1
    fi
    
    if ! grep -q "^$RENEW_PASS|" "$DB_FILE"; then
        echo -e "➜ Error: Password tidak ditemukan."
        exit 1
    fi
    
    old_line=$(grep "^$RENEW_PASS|" "$DB_FILE")
    old_duration=$(echo "$old_line" | cut -d'|' -f2)
    old_exp=$(echo "$old_line" | cut -d'|' -f3)
    
    if [[ "$old_duration" == *"Menit"* ]]; then
        echo -e "➜ Error: Akun trial tidak dapat diperpanjang!"
        exit 1
    fi
    
    today_epoch=$(date +%s)
    
    # Perbaikan kalkulasi waktu menggunakan aritmetika Bash (detik) untuk menghindari galat date
    added_seconds=$((RENEW_DAYS * 86400))
    if [[ -n "$old_exp" && "$old_exp" =~ ^[0-9]+$ && "$old_exp" -gt "$today_epoch" ]]; then
        new_exp=$((old_exp + added_seconds))
    else
        new_exp=$((today_epoch + added_seconds))
    fi
    
    sed -i "/^$RENEW_PASS|/d" "$DB_FILE"
    echo "$RENEW_PASS|$RENEW_DAYS Hari|$new_exp" >> "$DB_FILE"
    sync_to_zivpn_json
    
    readable_exp=$(date -d "@$new_exp" "+%Y-%m-%d %H:%M:%S")
    echo -e "\n========================================="
    echo -e "      SUKSES MEMPERPANJANG AKUN PREMIUM  "
    echo -e "========================================="
    echo -e " Host/Domain: $CURRENT_DOMAIN"
    echo -e " Password   : $RENEW_PASS"
    echo -e " Masa Aktif : $RENEW_DAYS Hari"
    echo -e " Expired On : $readable_exp"
    echo -e " Port Range : 6000 - 19999 (UDP)"
    echo -e "=========================================\n"
    ;;
    
  'trial')
    TRIAL_MINUTES="$2"
    
    if [[ -z "$TRIAL_MINUTES" ]]; then
        if [ -t 0 ]; then
            echo -e "\n========================================="
            echo -e "           BUAT AKUN TRIAL               "
            echo -e "========================================="
            read -p " Masukkan Durasi (Menit): " TRIAL_MINUTES
        else
            TRIAL_MINUTES=30
        fi
    fi
    
    if [[ -z "$TRIAL_MINUTES" || ! "$TRIAL_MINUTES" =~ ^[0-9]+$ ]]; then
        TRIAL_MINUTES=30
    fi
    
    TRIAL_PASS=$(shuf -i 100000-999999 -n 1)
    exp_date=$(date -d "+$TRIAL_MINUTES minutes" +%s)
    readable_exp=$(date -d "@$exp_date" "+%Y-%m-%d %H:%M:%S")
    echo "$TRIAL_PASS|$TRIAL_MINUTES Menit|$exp_date" >> "$DB_FILE"
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
        if [ -t 0 ]; then
            echo -e "\n========================================="
            echo -e "             HAPUS AKUN UDP              "
            echo -e "========================================="
            read -p " Masukkan password yang ingin dihapus: " DEL_PASS
        else
            echo "➜ Error: Password kosong."
            exit 1
        fi
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
            if [[ -z "$exp" || ! "$exp" =~ ^[0-9]+$ ]]; then
                readable_exp="Invalid/No Date"
                is_expired=true
            else
                readable_exp=$(date -d "@$exp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "Invalid Date")
                if [[ "$exp" -lt "$today_epoch" ]]; then
                    is_expired=true
                else
                    is_expired=false
                fi
            fi

            if [ "$is_expired" = true ]; then
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
    sync_to_zivpn_json
    ;;

  'del-expired')
    today_epoch=$(date +%s)
    count_before=$(wc -l < "$DB_FILE")
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
    count_after=$(wc -l < "$DB_FILE")
    deleted_count=$((count_before - count_after))
    echo "Selesai. Berhasil menghapus $deleted_count akun kedaluwarsa dari database."
    ;;

  'status')
    if systemctl is-active --quiet zivpn; then
        ZIVPN_STAT="Active"
    else
        ZIVPN_STAT="Inactive"
    fi
    if systemctl is-active --quiet z-api; then
        Z_API_STAT="Active"
    else
        Z_API_STAT="Inactive"
    fi
    echo "ZIVPN_STAT:$ZIVPN_STAT|Z_API_STAT:$Z_API_STAT"
    ;;

  'restart')
    systemctl restart zivpn >/dev/null 2>&1
    systemctl restart z-api >/dev/null 2>&1
    echo "Done"
    ;;

  'update')
    sync_to_zivpn_json
    systemctl restart zivpn >/dev/null 2>&1
    systemctl restart z-api >/dev/null 2>&1
    echo "Layanan berhasil diperbarui dan dijalankan ulang."
    ;;
    
  *)
    echo -e "\n Gunakan perintah: zi.sh [install|uninstall|api|add|renew|trial|del|list|domain|backup|restore|clean|del-expired|status|restart|update]\n"
    ;;
esac
