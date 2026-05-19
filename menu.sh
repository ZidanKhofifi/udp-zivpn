#!/bin/bash

# Warna untuk tampilan terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# URL skrip inti sebagai engine utama
ENGINE_URL="https://raw.githubusercontent.com/potatonc/zivpn-udp/refs/heads/main/zi.sh"

# Pastikan dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Silakan jalankan skrip ini sebagai root (sudo su).${NC}"
    exit 1
fi

while true; do
    clear
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${GREEN}       Z-TUNNEL UDP MENU MANAGER         ${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo -e " 1. Buat Akun UDP (Premium/Trial)"
    echo -e " 2. Lihat Daftar Semua Akun (List)"
    echo -e " 3. Hapus Akun UDP"
    echo -e " 4. Backup Konfigurasi & Akun"
    echo -e " 5. Restore Konfigurasi & Akun"
    echo -e " 6. Keluar"
    echo -e "${CYAN}=========================================${NC}"
    read -p " Pilih opsi [1-6]: " menu_choice

    case $menu_choice in
        1)
            clear
            echo -e "${YELLOW}=========================================${NC}"
            echo -e "${YELLOW}         PROSES PEMBUATAN AKUN           ${NC}"
            echo -e "${YELLOW}=========================================${NC}"
            echo -e "${BLUE}[*] Menghubungkan ke fungsi engine Potato...${NC}"
            echo ""
            # Langsung panggil fungsi add milik potato secara interaktif
            bash <(wget -qO- "$ENGINE_URL") add
            echo ""
            echo -e "${CYAN}=========================================${NC}"
            read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali ke menu..."
            ;;
            
        2)
            clear
            echo -e "${GREEN}[*] Menampilkan Daftar Akun Aktif:${NC}"
            echo "========================================="
            bash <(wget -qO- "$ENGINE_URL") list
            echo "========================================="
            echo ""
            read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali ke menu..."
            ;;
            
        3)
            clear
            echo -e "${RED}=========================================${NC}"
            echo -e "${RED}             HAPUS AKUN UDP              ${NC}"
            echo -e "${RED}=========================================${NC}"
            echo -e "${BLUE}[*] Menghubungkan ke fungsi engine Potato...${NC}"
            echo ""
            # Langsung panggil fungsi del milik potato secara interaktif
            bash <(wget -qO- "$ENGINE_URL") del
            echo ""
            echo -e "${RED}=========================================${NC}"
            read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali ke menu..."
            ;;
            
        4)
            clear
            echo -e "${YELLOW}[*] Memulai Proses Backup Konfigurasi...${NC}"
            bash <(wget -qO- "$ENGINE_URL") backup
            echo ""
            read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali ke menu..."
            ;;
            
        5)
            clear
            echo -e "${YELLOW}[*] Memulai Proses Restore Konfigurasi...${NC}"
            bash <(wget -qO- "$ENGINE_URL") restore
            echo ""
            read -n 1 -s -r -p "Tekan tombol apa saja untuk kembali ke menu..."
            ;;
            
        6)
            clear
            echo -e "${GREEN}Terima kasih telah menggunakan Z-Tunnel Manager!${NC}"
            exit 0
            ;;
            
        *)
            echo -e "${RED}Pilihan tidak tersedia!${NC}"
            sleep 1
            ;;
    esac
done
