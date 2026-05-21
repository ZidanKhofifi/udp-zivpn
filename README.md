# Z-Tunnel UDP ZiVPN Manager (Premium Potato Mod)

Panduan ringkas untuk pemasangan, pembaruan, dan penghapusan sistem manajemen ZiVPN UDP Server.


# =====================
# 1. PERINTAH INSTALASI (INSTALL)
# =====================
```bash
apt-get update -y && apt-get install curl wget -y; rm -f /usr/bin/install.sh /usr/bin/menu.sh; wget -q --no-cache -O /usr/bin/install.sh "https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/install.sh"; chmod +x /usr/bin/install.sh && bash /usr/bin/install.sh

```
# =====================
# 2. PERINTAH PEMBARUAN (UPDATE)
# =====================
```bash
rm -f /usr/bin/install.sh /usr/bin/menu.sh /usr/local/bin/zi.sh; wget -q --no-cache -O /usr/bin/install.sh "https://raw.githubusercontent.com/ZidanKhofifi/udp-zivpn/main/install.sh"; chmod +x /usr/bin/install.sh && bash /usr/bin/install.sh
```
# =====================
# 3. PERINTAH PENGHAPUSAN (UNINSTALL)
# =====================
```bash
bash /usr/local/bin/zi.sh uninstall && sed -i '/menu.sh/d' ~/.bashrc && rm -f /usr/local/bin/zi.sh /usr/bin/menu.sh /usr/bin/install.sh
````
