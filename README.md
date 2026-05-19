# Z-Tunnel UDP ZiVPN Manager

Skrip manajemen otomatis untuk mengelola biner asli **ZiVPN UDP Server** berbasis otentikasi **Password-Only** (Tanpa Username). Skrip ini menggunakan core engine terpercaya yang ringan, cepat (*fast connect*), dan hemat konsumsi RAM pada VPS.

## ⚡ Fitur Utama
* **Buat Akun UDP (Premium/Trial)**: Sistem manajemen tanggal dan trial otomatis yang dibuat langsung pada skrip menu lokal.
* **Lihat Daftar Semua Akun (List)**: Menampilkan seluruh password aktif beserta tanggal kedaluwarsa dalam bentuk tabel yang rapi.
* **Hapus Akun Manual**: Menghapus data pelanggan langsung dari sistem database lokal.
* **Auto-Login Menu**: Begitu instalasi selesai, setiap kali masuk atau login ke VPS, menu manajemen akan otomatis langsung terbuka.

---

## 📋 Persyaratan Sistem
* **Sistem Operasi**: Ubuntu 20.04 LTS / Ubuntu 22.04 LTS / Debian 11
* **Akses**: Root User (`sudo su`)

---

## ⚠️ INSTALL SCRIPT ⚠️

Masuk ke VPS baru via Termux/SSH, pastikan sudah masuk mode root dengan mengetik `sudo su`, lalu salin dan jalankan perintah di bawah ini secara utuh:

```bash
apt-get update -y && apt-get install curl -y; curl -k -sL "[https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/install.sh](https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/install.sh)" -o /usr/bin/install.sh; curl -k -sL "[https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/menu.sh](https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/menu.sh)" -o /usr/bin/menu.sh; chmod +x /usr/bin/install.sh /usr/bin/menu.sh; bash /usr/bin/install.sh

```

## update sc

```bash

curl -k -sL "[https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/update.sh](https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/update.sh)" -o /usr/bin/update.sh; chmod +x /usr/bin/update.sh; bash /usr/bin/update.sh

