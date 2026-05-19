#!/bin/bash

# Folder Database Sistem
DB_DIR="/etc/z-tunnel"
DB_FILE="$DB_DIR/database.db"
DOMAIN_FILE="$DB_DIR/domain"
ZIVPN_PASS_FILE="/var/lib/zivpn/passwords.txt"

# Warna Terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Pastikan Root & Folder Eksis
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Silakan jalankan sebagai root.${NC}"
    exit 1
fi
mkdir -p "$DB_DIR"
touch "$DB_FILE"
touch "$DOMAIN_FILE"

# Ambil data domain aktif
if [ ! -s "$DOMAIN_FILE" ]; then
    echo "Belum_Diatur" > "$DOMAIN_FILE"
fi
CURRENT_DOMAIN=$(cat "$DOMAIN_FILE")

# Fungsi Sinkronisasi Database ke Biner ZiVPN
sync_passwords() {
    today=$(date +%Y-%m-%d)
    awk -v t="$today" -F'|' '$3 >= t {print $1}' "$DB_FILE" > "$ZIVPN_PASS_FILE"
    chmod 777 "$ZIVPN_PASS_FILE"
    systemctl restart zivpn >/dev/null 2>&1
}

while true; do
    sync_passwords
    clear
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${GREEN}       Z-TUNNEL UDP MENU MANAGER         ${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo -e " Domain Server : ${YELLOW}$CURRENT_DOMAIN${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo -e " 1. Buat Akun Trial UDP (1 Hari)"
    echo -e " 2. Buat Akun Premium UDP (Manual)"
    echo -e " 3. Lihat Daftar Semua Akun (List)"
    echo -e " 4. Hapus Akun UDP"
    echo -e " 5. Ubah Domain Server"
    echo -e " 6. Keluar"
    echo -e "${CYAN}=========================================${NC}"
    read -p " Pilih opsi [1-6]: " menu_choice

    case $menu_choice in
        1)
            clear
            echo -e "${YELLOW}[*] Membuat Akun Trial UDP (1 Hari)...${NC}"
            TRIAL_PASS=$(shuf -i 100000-999999 -n 1)
            exp_date=$(date -d "+1 day" +%Y-%m-%d)
            
            echo "$TRIAL_PASS|1|$exp_date" >> "$DB_FILE"
            
            echo -e "${GREEN}=========================================${NC}"
            echo -e "${GREEN}      SUKSES MEMBUAT AKUN TRIAL          ${NC}"
            echo -e "${GREEN}=========================================${NC}"
            echo -e " Host/Domain: $CURRENT_DOMAIN"
            echo -e " Password   : $TRIAL_PASS"
            echo -e " Masa Aktif : 1 Hari"
            echo -e " Expired On : $exp_date"
            echo -e "${GREEN}=========================================${NC}"
            read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali..."
            ;;
            
        2)
            clear
            echo -e "${YELLOW}=========================================${NC}"
            echo -e "${YELLOW}           BUAT AKUN PREMIUM             ${NC}"
            echo -e "${YELLOW}=========================================${NC}"
            read -p " Masukkan Password : " PREMIUM_PASS
            read -p " Masukkan Masa Aktif (Hari): " PREMIUM_DAYS
            
            if [[ -z "$PREMIUM_PASS" || -z "$PREMIUM_DAYS" || ! "$PREMIUM_DAYS" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}Error: Input salah atau tidak boleh kosong!${NC}"
                sleep 2
                continue
            fi
            
            if grep -q "^$PREMIUM_PASS|" "$DB_FILE"; then
                echo -e "${RED}Error: Password sudah digunakan!${NC}"
                sleep 2
                continue
            fi
            
            exp_date=$(date -d "+$PREMIUM_DAYS days" +%Y-%m-%d)
            echo "$PREMIUM_PASS|$PREMIUM_DAYS|$exp_date" >> "$DB_FILE"
            
            echo -e "${GREEN}=========================================${NC}"
            echo -e "${GREEN}      SUKSES MEMBUAT AKUN PREMIUM        ${NC}"
            echo -e "${GREEN}=========================================${NC}"
            echo -e " Host/Domain: $CURRENT_DOMAIN"
            echo -e " Password   : $PREMIUM_PASS"
            echo -e " Masa Aktif : $PREMIUM_DAYS Hari"
            echo -e " Expired On : $exp_date"
            echo -e "${GREEN}=========================================${NC}"
            read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali..."
            ;;
            
        3)
            clear
            echo -e "${GREEN}=====================================================${NC}"
            echo -e "${GREEN}               DAFTAR AKUN UDP ACTIVE                ${NC}"
            echo -e "${GREEN}=====================================================${NC}"
            printf "%-15s | %-12s | %-15s\n" "PASSWORD" "DURASI (HARI)" "TANGGAL EXPIRED"
            echo "-----------------------------------------------------"
            today=$(date +%Y-%m-%d)
            while IFS='|' read -r pass days exp; do
                if [[ -n "$pass" ]]; then
                    if [[ "$exp" < "$today" ]]; then
                        printf "%-15s | %-12s | %-15s ${RED}(Expired)${NC}\n" "$pass" "$days" "$exp"
                    else
                        printf "%-15s | %-12s | %-15s ${GREEN}(Aktif)${NC}\n" "$pass" "$days" "$exp"
                    fi
                fi
            done < "$DB_FILE"
            echo "====================================================="
            echo ""
            read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali..."
            ;;
            
        4)
            clear
            echo -e "${RED}=========================================${NC}"
            echo -e "${RED}             HAPUS AKUN UDP              ${NC}"
            echo -e "${RED}=========================================${NC}"
            read -p " Masukkan password yang ingin dihapus: " DEL_PASS
            
            if [ -z "$DEL_PASS" ]; then
                echo -e "${RED}Error: Password tidak boleh kosong!${NC}"
                sleep 2
                continue
            fi
            
            if ! grep -q "^$DEL_PASS|" "$DB_FILE"; then
                echo -e "${RED}Error: Password tidak ditemukan!${NC}"
                sleep 2
                continue
            fi
            
            sed -i "/^$DEL_PASS|/d" "$DB_FILE"
            echo -e "${GREEN}Akun '$DEL_PASS' berhasil dihapus dari database.${NC}"
            sleep 2
            ;;
            
        5)
            clear
            echo -e "${YELLOW}=========================================${NC}"
            echo -e "${YELLOW}          UBAH DOMAIN SERVER             ${NC}"
            echo -e "${YELLOW}=========================================${NC}"
            echo -e " Domain Saat Ini: $CURRENT_DOMAIN"
            read -p " Masukkan Domain Baru: " NEW_DOMAIN
            
            if [ -z "$NEW_DOMAIN" ]; then
                echo -e "${RED}Error: Domain tidak boleh kosong!${NC}"
                sleep 2
                continue
            fi
            
            echo "$NEW_DOMAIN" > "$DOMAIN_FILE"
            CURRENT_DOMAIN="$NEW_DOMAIN"
            echo -e "${GREEN}Domain berhasil diperbarui menjadi: $CURRENT_DOMAIN${NC}"
            sleep 2
            ;;
            
        6)
            clear
            exit 0
            ;;
        *)
            echo -e "${RED}Pilihan tidak tersedia!${NC}"
            sleep 1
            ;;
    esac
done
