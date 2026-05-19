#!/bin/bash

# Warna untuk tampilan terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0;3m' # No Color

# URL skrip inti sebagai engine utama
ENGINE_URL="https://raw.githubusercontent.com/potatonc/zivpn-udp/refs/heads/main/zi.sh"

# Pastikan dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Silakan jalankan skrip ini sebagai root (sudo su).${NC}"
    exit 1
fi

# Fungsi Tampilan Header Menu
clear
echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}       Z-TUNNEL UDP MENU MANAGER         ${NC}"
echo -e "${CYAN}=========================================${NC}"
echo -e " 1. Buat Akun Trial UDP (1 Hari)"
echo -e " 2. Buat Akun Premium UDP (Manual)"
echo -e " 3. Lihat Daftar Semua Akun (List)"
echo -e " 4. Hapus Akun UDP"
echo -e " 5. Backup Konfigurasi & Akun"
echo -e " 6. Restore Konfigurasi & Akun"
echo -e " 7. Keluar"
echo -e "${CYAN}=========================================${NC}"
read -p " Pilih opsi [1-7]: " menu_choice

case $menu_choice in
    1)
        # Opsi 1: Buat Akun Trial (Otomatis & Acak)
        clear
        echo -e "${YELLOW}[*] Membuat Akun Trial UDP (1 Hari)...${NC}"
        # Membuat password acak sepanjang 6 karakter (angka saja)
        TRIAL_PASS=$(value=$(shuf -i 100000-999999 -n 1); echo "$value")
        
        # Eksekusi penambahan akun via engine Potato di latar belakang
        # Menggunakan exp 1 hari secara otomatis
        bash <(wget -qO- "$ENGINE_URL") add "$TRIAL_PASS" 1 > /dev/null 2>&1
        
        echo -e "${GREEN}=========================================${NC}"
        echo -e "${GREEN}      SUKSES MEMBUAT AKUN TRIAL          ${NC}"
        echo -e "${GREEN}=========================================${NC}"
        echo -e " Password : $TRIAL_PASS"
        echo -e " Masa Aktif: 1 Hari"
        echo -e "${GREEN}=========================================${NC}"
        read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali ke menu..."
        bash /usr/bin/menu.sh
        ;;
        
    2)
        # Opsi 2: Buat Akun Premium (Input Manual)
        clear
        echo -e "${YELLOW}=========================================${NC}"
        echo -e "${YELLOW}           BUAT AKUN PREMIUM             ${NC}"
        echo -e "${YELLOW}=========================================${NC}"
        read -p " Masukkan Password : " PREMIUM_PASS
        read -p " Masukkan Masa Aktif (Hari): " PREMIUM_DAYS
        
        if [[ -z "$PREMIUM_PASS" || -z "$PREMIUM_DAYS" ]]; then
            echo -e "${RED}Error: Input tidak boleh kosong!${NC}"
            sleep 2
            bash /usr/bin/menu.sh
            exit 1
        fi
        
        # Eksekusi penambahan akun via engine Potato
        bash <(wget -qO- "$ENGINE_URL") add "$PREMIUM_PASS" "$PREMIUM_DAYS" > /dev/null 2>&1
        
        echo -e "${GREEN}=========================================${NC}"
        echo -e "${GREEN}      SUKSES MEMBUAT AKUN PREMIUM        ${NC}"
        echo -e "${GREEN}=========================================${NC}"
        echo -e " Password : $PREMIUM_PASS"
        echo -e " Masa Aktif: $PREMIUM_DAYS Hari"
        echo -e "${GREEN}=========================================${NC}"
        read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali ke menu..."
        bash /usr/bin/menu.sh
        ;;
        
    3)
        # Opsi 3: List Akun
        clear
        echo -e "${GREEN}[*] Menampilkan Daftar Akun Aktif:${NC}"
        bash <(wget -qO- "$ENGINE_URL") list
        echo ""
        read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali ke menu..."
        bash /usr/bin/menu.sh
        ;;
        
    4)
        # Opsi 4: Hapus Akun
        clear
        echo -e "${RED}=========================================${NC}"
        echo -e "${RED}             HAPUS AKUN UDP              ${NC}"
        echo -e "${RED}=========================================${NC}"
        read -p " Masukkan password yang ingin dihapus: " DEL_PASS
        
        if [ -z "$DEL_PASS" ]; then
            echo -e "${RED}Error: Password tidak boleh kosong!${NC}"
            sleep 2
            bash /usr/bin/menu.sh
            exit 1
        fi
        
        # Eksekusi hapus akun via engine Potato
        bash <(wget -qO- "$ENGINE_URL") del "$DEL_PASS"
        
        echo -e "${GREEN}Proses penghapusan akun '$DEL_PASS' selesai.${NC}"
        sleep 2
        bash /usr/bin/menu.sh
        ;;
        
    5)
        # Opsi 5: Backup Konfigurasi
        clear
        echo -e "${YELLOW}[*] Memulai Proses Backup Konfigurasi...${NC}"
        bash <(wget -qO- "$ENGINE_URL") backup
        echo ""
        read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali ke menu..."
        bash /usr/bin/menu.sh
        ;;
        
    6)
        # Opsi 6: Restore Konfigurasi
        clear
        echo -e "${YELLOW}[*] Memulai Proses Restore Konfigurasi...${NC}"
        bash <(wget -qO- "$ENGINE_URL") restore
        echo ""
        read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali ke menu..."
        bash /usr/bin/menu.sh
        ;;
        
    7)
        # Opsi 7: Keluar
        clear
        echo -e "${GREEN}Terima kasih telah menggunakan Z-Tunnel Manager!${NC}"
        exit 0
        ;;
        
    *)
        # Input Salah
        echo -e "${RED}Pilihan tidak tersedia!${NC}"
        sleep 1
        bash /usr/bin/menu.sh
        ;;
esac
