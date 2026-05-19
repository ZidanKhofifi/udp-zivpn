#!/bin/bash

while true; do
    clear
    CURRENT_DOMAIN=$(cat /etc/z-tunnel/domain 2>/dev/null || echo "Belum_Diatur")
    echo -e "\033[0;36m=========================================\033[0m"
    echo -e "\033[0;32m   Z-TUNNEL POTATO ENGINE PREMIUM MENU   \033[0m"
    echo -e "\033[0;36m=========================================\033[0m"
    echo -e " Domain Server : \033[0;33m$CURRENT_DOMAIN\033[0m"
    echo -e " Port Range    : \033[0;35m6000 - 19999 (UDP)\033[0m"
    echo -e "\033[0;36m=========================================\033[0m"
    echo -e " 1. Buat Akun Trial (1 Hari)"
    echo -e " 2. Buat Akun Premium"
    echo -e " 3. Lihat Daftar Semua Akun"
    echo -e " 4. Hapus Akun"
    echo -e " 5. Ubah Domain Server"
    echo -e " 6. Backup Database"
    echo -e " 7. Restore Database"
    echo -e " 8. Uninstaller Script"
    echo -e " 9. Keluar"
    echo -e "\033[0;36m=========================================\033[0m"
    read -p " Pilih opsi [1-9]: " opt

    case $opt in
        1) bash /usr/local/bin/zi.sh trial; read -n 1 -s -r -p "Tekan enter untuk kembali...";;
        2) bash /usr/local/bin/zi.sh add; read -n 1 -s -r -p "Tekan enter untuk kembali...";;
        3) bash /usr/local/bin/zi.sh list; read -n 1 -s -r -p "Tekan enter untuk kembali...";;
        4) bash /usr/local/bin/zi.sh del; read -n 1 -s -r -p "Tekan enter untuk kembali...";;
        5) bash /usr/local/bin/zi.sh domain; read -n 1 -s -r -p "Tekan enter untuk kembali...";;
        6) bash /usr/local/bin/zi.sh backup; read -n 1 -s -r -p "Tekan enter untuk kembali...";;
        7) bash /usr/local/bin/zi.sh restore; read -n 1 -s -r -p "Tekan enter untuk kembali...";;
        8) 
            read -p "Apakah yakin ingin hapus SC? [y/n]: " yakin
            if [[ "$yakin" == "y" || "$yakin" == "Y" ]]; then
                bash /usr/local/bin/zi.sh uninstall
                sed -i '/menu.sh/d' ~/.bashrc
                rm -f /usr/local/bin/zi.sh /usr/bin/menu.sh
                exit 0
            fi
            ;;
        9) clear; exit 0;;
        *) echo "Pilihan tidak tersedia!"; sleep 1;;
    esac
done
