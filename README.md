# Z-Tunnel UDP ZiVPN Manager (Potato Engine)

Skrip manajemen otomatis untuk mengelola biner asli **ZiVPN UDP Server** menggunakan core engine terpercaya milik Potato yang ringan, kompatibel dengan versi `glibc` lama, cepat (*fast connect*), dan hemat konsumsi RAM pada VPS.

## ⚡ Fitur Utama
* **Custom Domain Server**: Menyimpan dan menampilkan alamat domain aktif langsung di header menu utama.
* **Buat Akun Trial UDP (1 Hari)**: Menghasilkan password acak sepanjang 6 digit secara instan untuk uji coba pelanggan.
* **Buat Akun Premium UDP (Manual)**: Bebas menentukan password khusus dan durasi masa aktif (hari) sesuai pesanan.
* **Lihat Daftar Semua Akun (List)**: Menampilkan seluruh password aktif beserta tanggal kedaluwarsa lengkap dengan status (Aktif/Expired) dalam bentuk tabel yang rapi.
* **Hapus Akun Manual**: Menghapus data pelanggan langsung dari sistem database lokal kapan saja.
* **Auto-Clear Expired Accounts**: Fitur pembersihan otomatis setiap hari melalui sistem Cron untuk menghapus akun yang telah melewati masa aktif.
* **Auto-Login Menu**: Begitu instalasi selesai, setiap kali masuk atau login kembali ke VPS, menu manajemen akan otomatis langsung terbuka.

---

## 📋 Persyaratan Sistem
* **Sistem Operasi**: Ubuntu 20.04 LTS / Ubuntu 22.04 LTS / Debian 11 / Debian 12
* **Akses**: Root User (`sudo su`)
* **VPS Segar**: Disarankan dipasang pada VPS segar (fresh) untuk menghindari bentrok penggunaan port `5600`.

---

## ⚠️ INSTALL SCRIPT ⚠️

Masuk ke VPS baru via Termux/SSH, pastikan sudah masuk mode root dengan mengetik `sudo su`, lalu salin dan jalankan perintah di bawah ini secara utuh:

```bash
apt-get update -y && apt-get install curl wget -y; rm -f /usr/bin/install.sh /usr/bin/menu.sh; wget -q --no-cache -O /usr/bin/install.sh "[https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/install.sh](https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/install.sh)"; wget -q --no-cache -O /usr/bin/menu.sh "[https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/menu.sh](https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/menu.sh)"; chmod +x /usr/bin/install.sh /usr/bin/menu.sh; bash /usr/bin/install.sh
```

##update

```bash

rm -f /usr/bin/update.sh && wget -q --no-cache -O /usr/bin/update.sh "[https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/update.sh](https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/update.sh)" && chmod +x /usr/bin/update.sh && bash /usr/bin/update.sh
