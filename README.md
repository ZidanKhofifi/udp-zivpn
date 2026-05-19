## ⚠️ INSTALL SCRIPT ⚠️

Masuk ke VPS baru via Termux/SSH, pastikan sudah masuk mode root (`sudo su`), lalu salin dan jalankan perintah di bawah ini:

```bash
curl -sL "[https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/install.sh](https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/install.sh)" -o /usr/bin/install.sh && curl -sL "[https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/menu.sh](https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/menu.sh)" -o /usr/bin/menu.sh && chmod +x /usr/bin/install.sh /usr/bin/menu.sh && bash /usr/bin/install.sh

```

## update script

```bash
curl -sL "[https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/update.sh](https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/update.sh)" -o /usr/bin/update.sh && chmod +x /usr/bin/update.sh && bash /usr/bin/update.sh
