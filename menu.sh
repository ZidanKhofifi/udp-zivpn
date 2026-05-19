#!/bin/bash

# Pastikan folder database ada
mkdir -p /var/lib/zivpn
mkdir -p /etc/z-tunnel
touch /var/lib/zivpn/passwords.txt

function menu_utama() {
    clear
    domain=$(cat /etc/z-tunnel/domain)
    port_sekarang=$(grep -oP '"server_port": "\K[^"]+' /etc/zivpn/config.json)
    
    echo "========================================="
    echo "       Z-TUNNEL UDP MENU MANAGER         "
    echo "========================================="
    echo " DOMAIN/HOST : $domain"
    echo " PORT UDP    : $port_sekarang"
    echo "========================================="
    echo " [1] Buat Akun Trial Zivpn"
    echo " [2] Buat Akun Premium Zivpn"
    echo " [3] Lihat Daftar Semua Akun (List)"
    echo " [4] Hapus Akun Zivpn"
    echo " ───────────────────────────────────────"
    echo " [5] Backup Data Akun"
    echo " [6] Restore Data Akun"
    echo " [7] Ubah Domain Server (Change Domain)"
    echo " [8] Ubah Port UDP Server"
    echo " [x] Keluar"
    echo "========================================="
    read -p "Pilih opsi [1-8 atau x]: " opsi

    case $opsi in
        1) buat_akun "trial" ;;
        2) buat_akun "premium" ;;
        3) lihat_daftar_akun ;;
        4) hapus_akun ;;
        5) backup_data ;;
        6) restore_data ;;
        7) ubah_domain ;;
        8) ubah_port ;;
        x|X) clear; exit 0 ;;
        *) echo "Pilihan tidak tersedia!"; sleep 1; menu_utama ;;
    esac
}

function buat_akun() {
    clear
    tipe_akun=$1
    
    if [[ "$tipe_akun" == "trial" ]]; then
        echo "========================================="
        echo "          BUAT AKUN TRIAL ZIVPN          "
        echo "========================================="
        password_acak="trial$((RANDOM % 90000 + 10000))"
        # Durasi trial diset hingga akhir hari berjalan (atau ganti sesuai kebutuhan)
        expired_time=$(date -d "tomorrow" +"%d %b %Y")
    else
        echo "========================================="
        echo "         BUAT AKUN PREMIUM ZIVPN         "
        echo "========================================="
        read -p "Masukkan Password Khusus: " password_acak
        if [[ -z "$password_acak" ]]; then
            echo "Password tidak boleh kosong!"
            sleep 1
            menu_utama
        fi
        # Memastikan tidak ada spasi atau karakter aneh
        password_acak=$(echo "$password_acak" | tr -d ' ')
        
        read -p "Masa Aktif Premium (Hari): " jumlah_hari
        if ! [[ "$jumlah_hari" =~ ^[0-9]+$ ]]; then
            echo "Harus berupa angka jumlah hari!"
            sleep 1
            menu_utama
        fi
        expired_time=$(date -d "$jumlah_hari days" +"%d %b %Y")
    fi

    domain=$(cat /etc/z-tunnel/domain)
    vps_isp=$(curl -s ipinfo.io/org | cut -d' ' -f2-)
    if [[ -z "$vps_isp" ]]; then
        vps_isp="NewMedia Express Pte Ltd"
    fi

    # Simpan ke database teks: FORMAT -> password | tanggal_expired
    echo "$password_acak | $expired_time" >> /var/lib/zivpn/passwords.txt
    systemctl restart zivpn &>/dev/null

    clear
    echo " _   _ ____  ____    __________     ______  _   _"
    echo "Success:"
    if [[ "$tipe_akun" == "trial" ]]; then
        echo "TRIAL AKUN ZIVPN"
    else
        echo "PREMIUM AKUN ZIVPN"
    fi
    echo "┌────────────────────────┐"
    echo "│ Host   : $domain"
    echo "│ Pass   : $password_acak"
    echo "│ ISP    : $vps_isp"
    echo "│ Expire : $expired_time"
    echo "└────────────────────────┘"
    echo "Terima kasih telah menggunakan layanan kami"
    echo ""
    read -p "Tekan Enter untuk kembali ke menu..."
    menu_utama
}

function lihat_daftar_akun() {
    clear
    echo "========================================="
    echo "         DAFTAR SEMUA AKUN AKTIF         "
    echo "========================================="
    echo "   PASSWORD    |    EXPIRED DATE         "
    echo "─────────────────────────────────────────"
    if [ ! -s /var/lib/zivpn/passwords.txt ]; then
        echo "       ( Belum ada akun terdaftar )"
    else
        cat /var/lib/zivpn/passwords.txt | awk -F ' \\| ' '{printf " %-13s | %-15s\n", \$1, \$2}'
    fi
    echo "========================================="
    read -p "Tekan [Enter] untuk kembali ke menu..."
    menu_utama
}

function hapus_akun() {
    clear
    echo "========================================="
    echo "            HAPUS AKUN ZIVPN             "
    echo "========================================="
    read -p "Masukkan Password yang ingin dihapus: " pass_hapus
    
    if [[ -z "$pass_hapus" ]]; then
        menu_utama
    fi

    if grep -q "^$pass_hapus " /var/lib/zivpn/passwords.txt || grep -q "^$pass_hapus$" /var/lib/zivpn/passwords.txt; then
        sed -i "/^$pass_hapus /d" /var/lib/zivpn/passwords.txt
        sed -i "/^$pass_hapus$/d" /var/lib/zivpn/passwords.txt
        systemctl restart zivpn &>/dev/null
        echo ""
        echo "Akun dengan password '$pass_hapus' berhasil dihapus!"
    else
        echo ""
        echo "Password tidak ditemukan di database!"
    fi
    sleep 2
    menu_utama
}

function backup_data() {
    clear
    echo "========================================="
    echo "            BACKUP DATA AKUN             "
    echo "========================================="
    echo "[+] Mengompres data database..."
    sleep 1
    
    mkdir -p /root/zivpn_backup
    cp /var/lib/zivpn/passwords.txt /root/zivpn_backup/
    cp /etc/zivpn/config.json /root/zivpn_backup/
    cp /etc/z-tunnel/domain /root/zivpn_backup/
    
    cd /root
    tar -czf zivpn-backup.tar.gz zivpn_backup
    rm -rf /root/zivpn_backup
    
    mv zivpn-backup.tar.gz /root/backup_zivpn.tar.gz
    
    echo "========================================="
    echo " BACKUP SELESAI!"
    echo " File disimpan di: /root/backup_zivpn.tar.gz"
    echo " Silakan unduh file tersebut ke HP Anda."
    echo "========================================="
    read -p "Tekan [Enter] untuk kembali..."
    menu_utama
}

function restore_data() {
    clear
    echo "========================================="
    echo "            RESTORE DATA AKUN            "
    echo "========================================="
    if [ ! -f /root/backup_zivpn.tar.gz ]; then
        echo "Error: File /root/backup_zivpn.tar.gz tidak ditemukan!"
        echo "Pastikan file backup sudah diunggah ke folder /root/"
        sleep 3
        menu_utama
    fi

    echo "[+] Memulihkan data konfigurasi dan database..."
    cd /root
    tar -xzf backup_zivpn.tar.gz
    
    cp zivpn_backup/passwords.txt /var/lib/zivpn/
    cp zivpn_backup/config.json /etc/zivpn/
    cp zivpn_backup/domain /etc/z-tunnel/
    
    rm -rf zivpn_backup
    systemctl restart zivpn &>/dev/null
    
    echo "========================================="
    echo " RESTORE SELESAI! Semua data telah pulih."
    echo "========================================="
    sleep 2
    menu_utama
}

function ubah_domain() {
    clear
    echo "========================================="
    echo "         UBAH DOMAIN / HOST SERVER       "
    echo "========================================="
    echo " Domain saat ini: $(cat /etc/z-tunnel/domain)"
    echo "─────────────────────────────────────────"
    read -p "Masukkan Domain Baru Anda: " domain_baru
    
    if [[ -z "$domain_baru" ]]; then
        echo "Domain tidak boleh kosong!"
        sleep 1
        menu_utama
    fi

    echo "$domain_baru" > /etc/z-tunnel/domain
    echo ""
    echo "Domain berhasil diperbarui menjadi: $domain_baru"
    sleep 2
    menu_utama
}

function ubah_port() {
    clear
    echo "========================================="
    echo "            UBAH PORT UDP SERVER         "
    echo "========================================="
    echo " Port saat ini: $(grep -oP '"server_port": "\K[^"]+' /etc/zivpn/config.json)"
    echo "─────────────────────────────────────────"
    read -p "Masukkan Port Baru (Contoh: 5600): " port_baru
    
    if [[ -z "$port_baru" ]]; then
        menu_utama
    fi

    sed -i 's/"server_port": "[^"]*"/"server_port": "'"$port_baru"'"/g' /etc/zivpn/config.json
    systemctl restart zivpn
    
    echo ""
    echo "Port berhasil diubah ke $port_baru dan layanan dimuat ulang."
    sleep 2
    menu_utama
}

# Eksekusi Awal Menu
menu_utama
