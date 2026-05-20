#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

REBOOT_CRON_FILE="/etc/cron.d/vps-reboot"

check_auto_reboot() {
    if [ -f "$REBOOT_CRON_FILE" ]; then
        local cron_time=$(cat "$REBOOT_CRON_FILE" | grep -v "#" | head -n 1 | awk '{print $2":"$1}')
        if [ -n "$cron_time" ]; then
            echo -e "${GREEN}Aktif ($cron_time)${NC}"
        else
            echo -e "${RED}Nonaktif${NC}"
        fi
    else
        echo -e "${RED}Nonaktif${NC}"
    fi
}

configure_auto_reboot() {
    clear
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${GREEN}         PENGATURAN AUTO REBOOT          ${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo -e " Status Saat Ini: $(check_auto_reboot)"
    echo -e " [1] Aktifkan Auto Reboot Harian"
    echo -e " [2] Nonaktifkan Auto Reboot Harian"
    echo -e " [3] Kembali ke Menu Utama"
    echo -e "${CYAN}=========================================${NC}"
    read -p " Pilih opsi [1-3]: " arb_opt

    case $arb_opt in
        1)
            read -p " Masukkan jam reboot (format 24 jam, contoh: 05): " hour
            read -p " Masukkan menit reboot (contoh: 00): " minute
            
            if [[ "$hour" =~ ^[0-9]+$ && "$minute" =~ ^[0-9]+$ && "$hour" -le 23 && "$minute" -le 59 ]]; then
                echo "$minute $hour * * * root /sbin/reboot" > "$REBOOT_CRON_FILE"
                chmod 644 "$REBOOT_CRON_FILE"
                systemctl restart cron >/dev/null 2>&1
                echo -e "\n${GREEN}✔ Auto Reboot berhasil diatur pada pukul $hour:$minute setiap hari!${NC}"
            else
                echo -e "\n${RED}✗ Format waktu tidak valid! Gagal menyimpan.${NC}"
            fi
            sleep 2
            ;;
        2)
            if [ -f "$REBOOT_CRON_FILE" ]; then
                rm -f "$REBOOT_CRON_FILE"
                systemctl restart cron >/dev/null 2>&1
                echo -e "\n${GREEN}✔ Auto Reboot berhasil dinonaktifkan!${NC}"
            else
                echo -e "\n${YELLOW}ℹ Auto Reboot memang sudah dalam kondisi nonaktif.${NC}"
            fi
            sleep 2
            ;;
        3)
            return
            ;;
        *)
            echo -e "\n${RED}✗ Pilihan tidak tersedia!${NC}"
            sleep 1
            ;;
    esac
}

while true; do
    clear
    CURRENT_DOMAIN=$(cat /etc/z-tunnel/domain 2>/dev/null || echo "Belum_Diatur")
    
    if systemctl is-active --quiet zivpn; then
        ZIVPN_STATUS="${GREEN}Active${NC}"
    else
        ZIVPN_STATUS="${RED}Inactive${NC}"
    fi

    if systemctl is-active --quiet z-api; then
        ZAPI_STATUS="${GREEN}Active${NC}"
    else
        ZAPI_STATUS="${RED}Inactive${NC}"
    fi

    echo -e "${CYAN}=========================================${NC}"
    echo -e "${GREEN}   NAKAMA STORE - POTATO ENGINE PREMIUM   ${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo -e " Domain Server : ${YELLOW}$CURRENT_DOMAIN${NC}"
    echo -e " Port Range    : ${MAGENTA}6000 - 19999 (UDP)${NC}"
    echo -e "${CYAN}-----------------------------------------${NC}"
    echo -e " STATUS LAYANAN:"
    echo -e " • ZiVPN Server : $ZIVPN_STATUS"
    echo -e " • API Gateway  : $ZAPI_STATUS"
    echo -e " • Auto Reboot  : $(check_auto_reboot)"
    echo -e "${CYAN}=========================================${NC}"
    echo -e " [1]  Buat Akun Trial"
    echo -e " [2]  Buat Akun Premium"
    echo -e " [3]  Lihat Daftar Semua Akun"
    echo -e " [4]  Hapus Akun"
    echo -e " [5]  Ubah Domain Server"
    echo -e " [6]  Backup Database"
    echo -e " [7]  Restore Database"
    echo -e " [8]  Setup API Gateway Bot"
    echo -e " [9]  Restart Semua Layanan VPS"
    echo -e " [10] Atur Auto Reboot VPS"
    echo -e " [11] Perbarui Skrip & Engine (Update)"
    echo -e " [12] Uninstaller Script"
    echo -e " [13] Keluar"
    echo -e "${CYAN}=========================================${NC}"
    read -p " Pilih opsi [1-13]: " opt

    case $opt in
        1) bash /usr/local/bin/zi.sh trial; read -n 1 -s -r -p "Tekan enter untuk kembali...";;
        2) bash /usr/local/bin/zi.sh add; read -n 1 -s -r -p "Tekan enter untuk kembali...";;
        3) bash /usr/local/bin/zi.sh list; read -n 1 -s -r -p "Tekan enter untuk kembali...";;
        4) bash /usr/local/bin/zi.sh del; read -n 1 -s -r -p "Tekan enter untuk kembali...";;
        5) bash /usr/local/bin/zi.sh domain; read -n 1 -s -r -p "Tekan enter untuk kembali...";;
        6) bash /usr/local/bin/zi.sh backup; read -n 1 -s -r -p "Tekan enter untuk kembali...";;
        7) bash /usr/local/bin/zi.sh restore; read -n 1 -s -r -p "Tekan enter untuk kembali...";;
        8) bash /usr/local/bin/zi.sh api; read -n 1 -s -r -p "Tekan enter untuk kembali...";;
        9) 
            echo -e "\n⏳ Sedang melakukan restart layanan..."
            bash /usr/local/bin/zi.sh restart
            echo -e "${GREEN}✔ Layanan berhasil dinyalakan ulang!${NC}"
            sleep 2
            ;;
        10) configure_auto_reboot ;;
        11)
            echo -e "\n⏳ Sedang memeriksa dan memperbarui komponen skrip..."
            bash /usr/local/bin/zi.sh update
            echo -e "${GREEN}✔ Pembaruan skrip dan mesin berhasil dilakukan!${NC}"
            sleep 2
            ;;
        12) 
            read -p "Apakah yakin ingin hapus SC? [y/n]: " yakin
            if [[ "$yakin" == "y" || "$yakin" == "Y" ]]; then
                bash /usr/local/bin/zi.sh uninstall
                sed -i '/menu.sh/d' ~/.bashrc
                rm -f "$REBOOT_CRON_FILE"
                rm -f /usr/local/bin/zi.sh /usr/bin/menu.sh /usr/bin/install.sh
                exit 0
            fi
            ;;
        13) clear; exit 0;;
        *) echo "Pilihan tidak tersedia!"; sleep 1;;
    esac
done
