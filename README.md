# Z-Tunnel UDP ZiVPN Manager

Skrip manajemen otomatis untuk mengelola biner asli **ZiVPN UDP Server** berbasis otentikasi **Password-Only** (Tanpa Username). Skrip ini dirancang khusus untuk penggunaan yang ringan, cepat (*fast connect*), dan hemat konsumsi RAM pada VPS.

## ⚡ Fitur Utama
* **Buat Akun Trial Otomatis**: Menghasilkan password acak dengan masa aktif 1 hari secara instan.
* **Buat Akun Premium Manual**: Bebas menentukan password khusus dan jumlah hari masa aktif sesuai pesanan.
* **Lihat Daftar Semua Akun (List)**: Menampilkan seluruh password aktif beserta tanggal kedaluwarsa dalam bentuk tabel yang rapi.
* **Hapus Akun Manual**: Menghapus data pelanggan dari database jika masa aktif habis atau melanggar aturan.
* **Auto-Clear Expired Accounts**: Fitur pembersihan otomatis setiap hari melalui sistem Cron untuk menghapus akun yang telah kedaluwarsa.
* **Backup & Restore**: Mencadangkan dan memulihkan seluruh database akun dengan aman dalam format kompresi `.tar.gz`.
* **Ubah Domain & Port Server**: Mengganti konfigurasi host/domain atau port UDP langsung dari menu navigasi tanpa instal ulang.

---

## 📋 Persyaratan Sistem
* **Sistem Operasi**: Ubuntu 20.04 LTS / Ubuntu 22.04 LTS / Debian 11
* **Akses**: Root User (`sudo su`)
* **VPS Kosong**: Sangat disarankan dipasang pada VPS segar (fresh) untuk menghindari bentrok port.

---

## 🚀 INSTALL SCRIPT 🚀

Masuk ke VPS baru via Termux/SSH, lalu salin dan tempel perintah di bawah ini secara langsung:

apt update && apt install wget -y && wget -O /usr/bin/install.sh "https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/install.sh" && wget -O /usr/bin/menu.sh "https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/menu.sh" && chmod +x /usr/bin/install.sh /usr/bin/menu.sh && install.sh

*Tunggu hingga proses kompilasi selesai. Setelah sukses, skrip akan **otomatis langsung membuka menu utama** tanpa perlu mengetik apa pun lagi.*

---

## 🛠️ Cara Penggunaan Selanjutnya

Jika proses instalasi awal sudah selesai, untuk masuk kembali ke menu manajemen di kemudian hari, cukup ketik perintah singkat ini di terminal VPS:

menu.sh

### Pengaturan di Aplikasi ZiVPN (Sisi Pelanggan):
1. Pastikan subdomain/domain di Cloudflare telah diatur ke status **DNS Only (Awan Abu-Abu)**.
2. Buka aplikasi ZiVPN di HP Android/iOS.
3. Masuk ke menu **UDP Tunnel**.
4. Pada kolom **udp server**, masukkan alamat domain atau IP VPS (tanpa perlu menuliskan port).
5. Pada kolom **udp password**, masukkan sandi yang telah dibuat melalui menu manajemen.
6. Klik **Apply** dan tekan **Start**.

---

## 📂 Struktur Direktori Sistem
* `/etc/zivpn/config.json` : File konfigurasi utama biner (Port & Banner).
* `/var/lib/zivpn/passwords.txt` : File database lokal tempat menyimpan password pelanggan dan tanggal kedaluwarsa.
* `/etc/z-tunnel/domain` : File penyimpanan data nama domain server aktif.
* `/etc/cron.daily/zivpn-cleaner` : Skrip pembersih otomatis harian untuk akun *expired*.
* 
