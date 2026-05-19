#!/bin/bash
DB_DIR="/etc/z-tunnel"
DB_FILE="$DB_DIR/database.db"
DOMAIN_FILE="$DB_DIR/domain"
Dir="/etc/zivpn"
FileBackup="/root/config.json.zivpn"
mkdir -p "$DB_DIR" "$Dir"

sync_to_zivpn_json() {
    today=$(date +%Y-%m-%d)
    cat <<EOF > "$Dir/config.json"
{
  "listen": ":5667",
  "cert": "$Dir/zivpn.crt",
  "key": "$Dir/zivpn.key",
  "obfs": "zivpn",
  "auth": { "mode": "passwords", "config": [
EOF
    first=true
    while IFS='|' read -r pass days exp; do
        exp_num=$(echo "$exp" | tr -d '-')
        today_num=$(date +%Y%m%d)
        if [[ -n "$pass" && "$exp_num" -ge "$today_num" ]]; then
            echo "${first:+ ,} \"$pass\"" >> "$Dir/config.json"
            first=false
        fi
    done < "$DB_FILE"
    cat <<EOF >> "$Dir/config.json"
  ] }
}
EOF
    systemctl restart zivpn 2>/dev/null
}

case "$1" in
  'add')
    if [ -n "$2" ] && [ -n "$3" ]; then PASS="$2"; DAYS="$3"; 
    else read -p " Password: " PASS; read -p " Hari: " DAYS; fi
    exp_date=$(date -d "+$DAYS days" +%Y-%m-%d)
    echo "$PASS|$DAYS|$exp_date" >> "$DB_FILE"
    sync_to_zivpn_json
    echo -e "SUKSES MEMBUAT AKUN PREMIUM\nPassword: $PASS\nExpired: $exp_date"
    ;;
  'del')
    if [ -n "$2" ]; then PASS="$2"; else read -p " Password: " PASS; fi
    sed -i "/^$PASS|/d" "$DB_FILE"
    sync_to_zivpn_json
    echo "Akun $PASS berhasil dihapus."
    ;;
  'list')
    echo -e "PASSWORD | DURASI | EXPIRED\n---------------------------"
    [ -f "$DB_FILE" ] && awk -F'|' '{printf "%-8s | %-6s | %-10s\n", $1, $2, $3}' "$DB_FILE"
    ;;
  'trial')
    PASS=$(shuf -i 100000-999999 -n 1)
    exp_date=$(date -d "+1 day" +%Y-%m-%d)
    echo "$PASS|1|$exp_date" >> "$DB_FILE"
    sync_to_zivpn_json
    echo -e "SUKSES AKUN TRIAL\nPassword: $PASS\nExpired: $exp_date"
    ;;
  'domain')
    read -p " Domain Baru: " NEW_DOMAIN
    echo "$NEW_DOMAIN" > "$DOMAIN_FILE"
    echo "Domain diubah ke $NEW_DOMAIN"
    ;;
  'backup')
    cp "$DB_FILE" "$FileBackup"
    echo "Database dibackup ke $FileBackup"
    ;;
  'restore')
    if [ -f "$FileBackup" ]; then cp "$FileBackup" "$DB_FILE"; sync_to_zivpn_json; echo "Restore berhasil."; fi
    ;;
  'api')
    # Jalankan Setup API Anda (seperti fungsi SetupAPI sebelumnya)
    echo "Menjalankan konfigurasi API..."
    ;;
  *) echo "Gunakan: [add|del|list|trial|domain|backup|restore|api]" ;;
esac
