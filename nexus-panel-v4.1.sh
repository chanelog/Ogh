#!/bin/bash
# ================================================================
#   OGH-PANELL v4.1
#   SSH + UDP Custom + ZIVPN + Xray (VMess/VLess/Trojan)
#   Auto-install binary saat pertama kali dijalankan
#   Warna tunggal: Biru Langit (Cyan)
#   Shortcut: ketik 'menu' dari terminal
# ================================================================

# ── Warna ─────────────────────────────────────────────────────
CB='\033[1;36m'   # Cyan Bold  — judul, pilihan, highlight
CD='\033[0;36m'   # Cyan Dim   — sub-teks, label
CW='\033[1;37m'   # Putih Bold — nilai penting
DM='\033[0;90m'   # Abu Gelap  — border, garis
GR='\033[1;32m'   # Hijau      — AKTIF / sukses
RD='\033[0;31m'   # Merah      — MATI / error
YL='\033[1;33m'   # Kuning     — warning / expired
NC='\033[0m'
BD='\033[1m'

# ── Path ──────────────────────────────────────────────────────
PD="/etc/nexus-panel"
XD="/usr/local/etc/xray"
XB="/usr/local/bin/xray"
XC="$XD/config.json"
XDB="$PD/xray_users.db"
UDB="$PD/users.db"
UDPC_DB="$PD/udpc_users.db"
ZIVPN_DB="$PD/zivpn_users.db"
DOMAIN_FILE="$PD/domain.conf"
LOG_FILE="$PD/panel.log"
FLAG="$PD/.installed"

# ── URL Binary ────────────────────────────────────────────────
XRAY_VER="v1.8.13"
XRAY_AMD="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VER}/Xray-linux-64.zip"
XRAY_ARM="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VER}/Xray-linux-arm64-v8a.zip"
UDPC_AMD="https://raw.githubusercontent.com/feely666/udp-custom/main/udp-custom-linux-amd64"
ZIVPN_AMD="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64"
ZIVPN_ARM="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64"
BADVPN_AMD="https://github.com/idtunnel/UDPGW-SSH/raw/master/badvpn-udpgw64"
BADVPN_ARM="https://github.com/idtunnel/UDPGW-SSH/raw/master/badvpn-udpgw"

# ── Helper ────────────────────────────────────────────────────
check_root(){ [[ $EUID -ne 0 ]] && echo -e "${RD}[!] Harus dijalankan sebagai root!${NC}" && exit 1; }
log(){ echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE" 2>/dev/null; }
get_ip(){ curl -s --max-time 5 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}'; }
get_dom(){ [[ -f "$DOMAIN_FILE" ]] && cat "$DOMAIN_FILE" || get_ip; }
get_arch(){ uname -m | grep -qE "aarch64|arm64" && echo "arm64" || echo "amd64"; }
gen_uuid(){ cat /proc/sys/kernel/random/uuid 2>/dev/null || python3 -c "import uuid;print(uuid.uuid4())"; }

ok()  { echo -e "  ${GR}[✔]${NC} $*"; }
err() { echo -e "  ${RD}[✘]${NC} $*"; }
info(){ echo -e "  ${CB}[•]${NC} $*"; }
warn(){ echo -e "  ${YL}[!]${NC} $*"; }
press_enter(){ echo ""; read -rp "$(echo -e "  ${CD}Tekan ${CW}[Enter]${CD} untuk kembali...${NC}")"; }
svc_on(){ systemctl is-active --quiet "$1" 2>/dev/null; }
svc_st(){ svc_on "$1" && echo -e "${GR}AKTIF${NC}" || echo -e "${RD}MATI${NC}"; }
svc_dot(){ svc_on "$1" && echo -e "${GR}●${NC}" || echo -e "${RD}●${NC}"; }

# ── Garis Box ─────────────────────────────────────────────────
# Lebar 60 karakter dalam box
L_TOP(){ echo -e "${DM}╔════════════════════════════════════════════════════════════╗${NC}"; }
L_MID(){ echo -e "${DM}╠════════════════════════════════════════════════════════════╣${NC}"; }
L_SEP(){ echo -e "${DM}╟────────────────────────────────────────────────────────────╢${NC}"; }
L_BOT(){ echo -e "${DM}╚════════════════════════════════════════════════════════════╝${NC}"; }
L_DIV(){ echo -e "${DM}╠═══════════════════════════════╦════════════════════════════╣${NC}"; }
L_COL(){ echo -e "${DM}║                               ║                            ║${NC}"; }

# ── LOGO ASCII OGH-PANELL ─────────────────────────────────────
show_logo(){
  echo -e "${CB}"
  echo '   ___   ____  _   _        ____   _    _   _ _____  _     _     '
  echo '  / _ \ / ___|| | | |      |  _ \ / \  | \ | | ____|| |   | |   '
  echo ' | | | | |  _ | |_| |______| |_) / _ \ |  \| |  _|  | |   | |   '
  echo ' | |_| | |_| ||  _  |______|  __/ ___ \| |\  | |___ | |___| |___'
  echo '  \___/ \____||_| |_|      |_| /_/   \_\_| \_|_____||_____|_____|'
  echo -e "${NC}"
  echo -e "${CD}              ✦  SSH  •  UDP  •  VMess  •  VLess  •  Trojan  ✦${NC}"
  echo -e "${DM}              ════════════════════════════════════════════════${NC}"
  echo ""
}

# ── Header Info Server ────────────────────────────────────────
header(){
  clear
  show_logo

  local IP=$(get_ip)
  local DOM=$(get_dom)
  local OS=$(lsb_release -ds 2>/dev/null | tr -d '"' | cut -c1-20 || echo "Linux")
  local UP=$(uptime -p 2>/dev/null | sed 's/up //' | cut -c1-20)
  local CPU=$(top -bn1 2>/dev/null | grep 'Cpu(s)' | awk '{printf "%.1f%%",$2+$4}')
  local RAM=$(free -h 2>/dev/null | awk '/^Mem:/{print $3"/"$2}')
  local DISK=$(df -h / 2>/dev/null | awk 'NR==2{print $3"/"$2" ("$5")"}')
  local LOAD=$(cut -d' ' -f1 /proc/loadavg 2>/dev/null)
  local CONN=$(ss -tnp 2>/dev/null | grep -c ESTAB || echo 0)
  local IFACE=$(ip -4 route ls 2>/dev/null | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
  local NOW=$(date '+%d/%m/%Y  %H:%M:%S')

  L_TOP
  printf "${DM}║${NC}  ${CB}${BD}%-60s${NC}${DM}║${NC}\n" "  INFO SERVER"
  L_MID
  printf "${DM}║${NC}  ${CD}IP Publik  :${NC} ${CB}%-20s${NC}  ${CD}Domain  :${NC} ${CB}%-14s${NC}  ${DM}║${NC}\n" "$IP" "$DOM"
  printf "${DM}║${NC}  ${CD}OS         :${NC} ${CW}%-20s${NC}  ${CD}Uptime  :${NC} ${CW}%-14s${NC}  ${DM}║${NC}\n" "${OS:0:20}" "${UP:0:14}"
  printf "${DM}║${NC}  ${CD}CPU Usage  :${NC} ${YL}%-20s${NC}  ${CD}Load    :${NC} ${YL}%-14s${NC}  ${DM}║${NC}\n" "$CPU" "$LOAD"
  printf "${DM}║${NC}  ${CD}RAM        :${NC} ${GR}%-20s${NC}  ${CD}Disk /  :${NC} ${GR}%-14s${NC}  ${DM}║${NC}\n" "$RAM" "$DISK"
  printf "${DM}║${NC}  ${CD}Interface  :${NC} ${CW}%-20s${NC}  ${CD}Koneksi :${NC} ${CW}%-14s${NC}  ${DM}║${NC}\n" "$IFACE" "${CONN} aktif"
  L_SEP
  printf "${DM}║${NC}  ${CD}Waktu      :${NC} ${CB}%-55s${NC}${DM}║${NC}\n" "$NOW"
  L_SEP
  # Baris status layanan — 2 kolom
  printf "${DM}║${NC}  $(svc_dot ssh)     ${CD}SSH/Dropbear${NC}    $(svc_dot stunnel4) ${CD}Stunnel4 SSL${NC}    $(svc_dot ws-ssh-80) ${CD}WebSocket${NC}           ${DM}║${NC}\n"
  printf "${DM}║${NC}  $(svc_dot xray)    ${CD}Xray V2Ray ${NC}    $(svc_dot udp-custom) ${CD}UDP Custom${NC}     $(svc_dot zivpn) ${CD}ZIVPN UDP${NC}           ${DM}║${NC}\n"
  L_BOT
  echo ""
}

sub_hdr(){
  echo ""
  L_TOP
  printf "${DM}║${NC}  ${CB}${BD}  %-58s${NC}${DM}║${NC}\n" "$1"
  L_BOT
  echo ""
}

# =================================================================
#   AUTO INSTALL — hanya sekali saat pertama kali
# =================================================================

do_auto_install(){
  clear
  echo ""
  echo -e "${CB}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CB}║        INSTALASI PERTAMA — OGH-PANELL v4.1                ║${NC}"
  echo -e "${CB}║        Jangan tutup terminal! Estimasi: 3-7 menit         ║${NC}"
  echo -e "${CB}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""

  local ARCH=$(get_arch)

  # ── 1. Paket Dasar ────────────────────────────────────────
  info "Instalasi paket dasar..."
  apt-get update -qq 2>/dev/null
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    curl wget unzip openssl python3 \
    openssh-server dropbear stunnel4 \
    squid nginx netcat-openbsd \
    iptables cron lsb-release net-tools \
    ufw 2>/dev/null
  ok "Paket dasar selesai"

  # ── 2. SSH (22, 2222) ─────────────────────────────────────
  info "Konfigurasi SSH..."
  # Bersihkan config port lama
  sed -i '/^#\?Port /d' /etc/ssh/sshd_config
  echo "Port 22"   >> /etc/ssh/sshd_config
  echo "Port 2222" >> /etc/ssh/sshd_config
  sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
  systemctl enable ssh 2>/dev/null; systemctl restart ssh 2>/dev/null
  ok "SSH aktif di port 22 & 2222"

  # ── 3. Dropbear (69, 109, 143) ────────────────────────────
  info "Konfigurasi Dropbear..."
  cat > /etc/default/dropbear <<'EOF'
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS="-p 143 -p 69"
DROPBEAR_BANNER=""
DROPBEAR_RECEIVE_WINDOW=65536
EOF
  systemctl enable dropbear 2>/dev/null; systemctl restart dropbear 2>/dev/null
  ok "Dropbear aktif di port 69, 109, 143"

  # ── 4. Stunnel4 (443, 444, 777) ───────────────────────────
  info "Konfigurasi Stunnel4..."
  mkdir -p /etc/stunnel
  openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
    -subj "/C=ID/ST=Jakarta/L=Jakarta/O=OGH/CN=ogh-panel" \
    -keyout /etc/stunnel/stunnel.key \
    -out    /etc/stunnel/stunnel.crt 2>/dev/null
  cat /etc/stunnel/stunnel.crt /etc/stunnel/stunnel.key > /etc/stunnel/stunnel.pem
  cat > /etc/stunnel/stunnel.conf <<'EOF'
pid = /var/run/stunnel4/stunnel4.pid
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1

[dropbear-ssl]
accept  = 443
connect = 127.0.0.1:109

[ssh-ssl]
accept  = 444
connect = 127.0.0.1:22

[ssh-ssl-2]
accept  = 777
connect = 127.0.0.1:2222
EOF
  sed -i 's/^ENABLED=.*/ENABLED=1/' /etc/default/stunnel4
  systemctl enable stunnel4 2>/dev/null; systemctl restart stunnel4 2>/dev/null
  ok "Stunnel4 aktif di port 443, 444, 777"

  # ── 5. WebSocket SSH (80, 8880, 8008) ─────────────────────
  info "Setup WebSocket SSH..."
  cat > /usr/local/bin/ws-ssh.py <<'PYEOF'
#!/usr/bin/env python3
import socket, threading, select, sys

LISTEN_HOST = '0.0.0.0'
LISTEN_PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 80
SSH_HOST    = '127.0.0.1'
SSH_PORT    = 22
BUFFER      = 65535
RESPONSE    = b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"

def pipe(src, dst):
    try:
        while True:
            r, _, _ = select.select([src], [], [], 60)
            if not r: break
            d = src.recv(BUFFER)
            if not d: break
            dst.sendall(d)
    except: pass
    for s in (src, dst):
        try: s.close()
        except: pass

def handle(client):
    try:
        req = client.recv(BUFFER)
        if not req: client.close(); return
        if b'HTTP' in req: client.sendall(RESPONSE)
        ssh = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        ssh.connect((SSH_HOST, SSH_PORT))
        for a, b in [(client, ssh), (ssh, client)]:
            threading.Thread(target=pipe, args=(a, b), daemon=True).start()
    except: client.close()

srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind((LISTEN_HOST, LISTEN_PORT))
srv.listen(200)
while True:
    c, _ = srv.accept()
    threading.Thread(target=handle, args=(c,), daemon=True).start()
PYEOF
  chmod +x /usr/local/bin/ws-ssh.py

  for PORT in 80 8880 8008; do
    cat > /etc/systemd/system/ws-ssh-${PORT}.service <<EOF
[Unit]
Description=WebSocket SSH Port ${PORT}
After=network.target
[Service]
ExecStart=/usr/bin/python3 /usr/local/bin/ws-ssh.py ${PORT}
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
    systemctl enable ws-ssh-${PORT} 2>/dev/null
    systemctl restart ws-ssh-${PORT} 2>/dev/null
  done
  ok "WebSocket SSH aktif di port 80, 8880, 8008"

  # ── 6. Xray (8443/8444/8445/8446/8553/8554/1194/2083) ────
  info "Install Xray-core ${XRAY_VER}..."
  mkdir -p "$XD" /var/log/xray
  local XZIP
  [[ "$ARCH" == "arm64" ]] && XZIP="$XRAY_ARM" || XZIP="$XRAY_AMD"
  wget -q "$XZIP" -O /tmp/xray.zip 2>/dev/null
  unzip -q -o /tmp/xray.zip -d /tmp/xr 2>/dev/null
  cp /tmp/xr/xray "$XB" 2>/dev/null && chmod +x "$XB"
  rm -rf /tmp/xray.zip /tmp/xr

  local UUID=$(gen_uuid)
  echo "$UUID" > "$PD/xray_master_uuid"

  openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
    -subj "/C=ID/O=OGH/CN=$(get_dom)" \
    -keyout "$XD/xray.key" -out "$XD/xray.crt" 2>/dev/null

  cat > "$XC" <<EOF
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray/access.log",
    "error":  "/var/log/xray/error.log"
  },
  "inbounds": [
    {"tag":"vmess-ws",    "port":8443,"protocol":"vmess",
     "settings":{"clients":[{"id":"$UUID","alterId":0}]},
     "streamSettings":{"network":"ws","wsSettings":{"path":"/vmess"}}},
    {"tag":"vmess-ws-tls","port":8553,"protocol":"vmess",
     "settings":{"clients":[{"id":"$UUID","alterId":0}]},
     "streamSettings":{"network":"ws","security":"tls",
       "tlsSettings":{"certificates":[{"certificateFile":"$XD/xray.crt","keyFile":"$XD/xray.key"}]},
       "wsSettings":{"path":"/vmess-tls"}}},
    {"tag":"vmess-tcp",   "port":1194,"protocol":"vmess",
     "settings":{"clients":[{"id":"$UUID","alterId":0}]},
     "streamSettings":{"network":"tcp"}},
    {"tag":"vmess-tcp-tls","port":2083,"protocol":"vmess",
     "settings":{"clients":[{"id":"$UUID","alterId":0}]},
     "streamSettings":{"network":"tcp","security":"tls",
       "tlsSettings":{"certificates":[{"certificateFile":"$XD/xray.crt","keyFile":"$XD/xray.key"}]}}},
    {"tag":"vless-ws",    "port":8444,"protocol":"vless",
     "settings":{"clients":[{"id":"$UUID"}],"decryption":"none"},
     "streamSettings":{"network":"ws","wsSettings":{"path":"/vless"}}},
    {"tag":"vless-ws-tls","port":8554,"protocol":"vless",
     "settings":{"clients":[{"id":"$UUID"}],"decryption":"none"},
     "streamSettings":{"network":"ws","security":"tls",
       "tlsSettings":{"certificates":[{"certificateFile":"$XD/xray.crt","keyFile":"$XD/xray.key"}]},
       "wsSettings":{"path":"/vless-tls"}}},
    {"tag":"trojan",      "port":8445,"protocol":"trojan",
     "settings":{"clients":[{"password":"ogh-trojan"}]},
     "streamSettings":{"network":"tcp"}},
    {"tag":"trojan-tls",  "port":8446,"protocol":"trojan",
     "settings":{"clients":[{"password":"ogh-trojan"}]},
     "streamSettings":{"network":"tcp","security":"tls",
       "tlsSettings":{"certificates":[{"certificateFile":"$XD/xray.crt","keyFile":"$XD/xray.key"}]}}}
  ],
  "outbounds":[
    {"protocol":"freedom","tag":"direct"},
    {"protocol":"blackhole","tag":"block"}
  ],
  "routing":{"rules":[
    {"type":"field","ip":["geoip:private"],"outboundTag":"block"}
  ]}
}
EOF

  cat > /etc/systemd/system/xray.service <<'EOF'
[Unit]
Description=Xray VMess/VLess/Trojan
After=network.target
[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable xray 2>/dev/null; systemctl start xray 2>/dev/null
  sleep 2
  svc_on xray && ok "Xray aktif di port 8443/8444/8445/8446/8553/8554/1194/2083" \
    || warn "Xray gagal start — cek: journalctl -u xray -n 20"

  # ── 7. BadVPN UDPGW (7100, 7200, 7300) ───────────────────
  info "Install BadVPN UDPGW..."
  local BVPN_URL
  [[ "$ARCH" == "arm64" ]] && BVPN_URL="$BADVPN_ARM" || BVPN_URL="$BADVPN_AMD"
  wget -q "$BVPN_URL" -O /usr/local/bin/badvpn-udpgw 2>/dev/null
  chmod +x /usr/local/bin/badvpn-udpgw
  for PORT in 7100 7200 7300; do
    cat > /etc/systemd/system/badvpn-${PORT}.service <<EOF
[Unit]
Description=BadVPN UDPGW Port ${PORT}
After=network.target
[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:${PORT} --max-clients 500 --max-connections-for-client 100
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
    systemctl enable badvpn-${PORT} 2>/dev/null
    systemctl restart badvpn-${PORT} 2>/dev/null
  done
  ok "BadVPN UDPGW aktif di port 7100, 7200, 7300"

  # ── 8. UDP Custom (25500) ─────────────────────────────────
  info "Install UDP Custom..."
  mkdir -p /etc/udp-custom
  wget -q "$UDPC_AMD" -O /usr/local/bin/udp-custom 2>/dev/null
  chmod +x /usr/local/bin/udp-custom
  cat > /etc/udp-custom/config.json <<'EOF'
{
  "listen": ":25500",
  "stream": { "type": "orig" },
  "auth": { "mode": "passwords", "config": [] },
  "log": { "level": "info" }
}
EOF
  cat > /etc/systemd/system/udp-custom.service <<'EOF'
[Unit]
Description=UDP Custom
After=network.target
[Service]
ExecStart=/usr/local/bin/udp-custom /etc/udp-custom/config.json
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable udp-custom 2>/dev/null; systemctl start udp-custom 2>/dev/null
  sleep 1
  svc_on udp-custom && ok "UDP Custom aktif di port 25500" || warn "UDP Custom: binary mungkin tidak kompatibel"

  # ── 9. ZIVPN UDP (5600) ───────────────────────────────────
  info "Install ZIVPN UDP..."
  mkdir -p /etc/zivpn
  local ZVPN_URL
  [[ "$ARCH" == "arm64" ]] && ZVPN_URL="$ZIVPN_ARM" || ZVPN_URL="$ZIVPN_AMD"
  wget -q "$ZVPN_URL" -O /usr/local/bin/zivpn 2>/dev/null
  chmod +x /usr/local/bin/zivpn
  cat > /etc/zivpn/config.json <<'EOF'
{
  "listen": ":5600",
  "stream": { "type": "zivpn" },
  "auth": { "mode": "passwords", "config": [] },
  "log": { "level": "info" }
}
EOF
  cat > /etc/systemd/system/zivpn.service <<'EOF'
[Unit]
Description=ZIVPN UDP
After=network.target
[Service]
ExecStart=/usr/local/bin/zivpn /etc/zivpn/config.json
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable zivpn 2>/dev/null; systemctl start zivpn 2>/dev/null
  sleep 1
  svc_on zivpn && ok "ZIVPN aktif di port 5600 (range 5000-9999)" || warn "ZIVPN: binary mungkin tidak kompatibel"

  # ── 10. Squid Proxy (3128, 8080) ──────────────────────────
  info "Setup Squid Proxy..."
  cat > /etc/squid/squid.conf <<'EOF'
http_port 3128
http_port 8080
acl all src all
http_access allow all
dns_v4_first on
forwarded_for off
request_header_access Via deny all
request_header_access X-Forwarded-For deny all
EOF
  systemctl enable squid 2>/dev/null; systemctl restart squid 2>/dev/null
  ok "Squid Proxy aktif di port 3128, 8080"

  # ── 11. UFW / Firewall ────────────────────────────────────
  info "Buka semua port di firewall..."
  if command -v ufw &>/dev/null; then
    ufw --force reset >/dev/null 2>&1
    ufw default allow incoming >/dev/null 2>&1
    ufw default allow outgoing >/dev/null 2>&1
    for P in 22 69 80 109 143 443 444 777 1194 2083 2222 \
             3128 5600 7100 7200 7300 8008 8080 8443 \
             8444 8445 8446 8553 8554 8880 25500; do
      ufw allow "$P" >/dev/null 2>&1
    done
    ufw allow 5000:9999/udp >/dev/null 2>&1
    ufw --force enable >/dev/null 2>&1
    ok "Firewall: semua port dibuka"
  fi

  # ── 12. Shortcut 'menu' ───────────────────────────────────
  info "Membuat shortcut 'menu'..."
  local SELF=$(readlink -f "$0")
  cp "$SELF" /usr/local/bin/menu 2>/dev/null
  chmod +x /usr/local/bin/menu
  ok "Shortcut 'menu' siap — ketik 'menu' dari terminal manapun"

  # ── Selesai ───────────────────────────────────────────────
  touch "$FLAG"
  log "Auto-install selesai"

  echo ""
  echo -e "${CB}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CB}║                                                            ║${NC}"
  echo -e "${CB}║   ✔  INSTALASI SELESAI — SEMUA LAYANAN AKTIF              ║${NC}"
  echo -e "${CB}║                                                            ║${NC}"
  echo -e "${CB}║   Ketik  'menu'  dari terminal untuk membuka panel         ║${NC}"
  echo -e "${CB}║                                                            ║${NC}"
  echo -e "${CB}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  read -rp "$(echo -e "  ${CD}Tekan ${CW}[Enter]${CD} untuk masuk ke panel...${NC}")"
}

# =================================================================
#   MANAJEMEN SSH
# =================================================================

_ssh_list(){
  echo -e "  ${CB}Daftar Akun SSH :${NC}"
  [[ -s "$UDB" ]] && while IFS='|' read -r u p exp _; do
    echo -e "  ${DM}•${NC} ${CW}$u${NC}  ${CD}exp:${NC} ${YL}$exp${NC}"
  done < "$UDB" || echo -e "  ${DM}(kosong)${NC}"
}

_ssh_buat(){
  header; sub_hdr "BUAT AKUN SSH"
  read -rp "$(echo -e "  ${CB}Username       :${NC} ")" USR
  read -rsp "$(echo -e "  ${CB}Password       :${NC} ")" PASS; echo ""
  read -rp "$(echo -e "  ${CB}Expired (hari) :${NC} ")" DAYS
  read -rp "$(echo -e "  ${CB}Limit IP (0=∞) :${NC} ")" LIM
  [[ -z "$USR" || -z "$PASS" || -z "$DAYS" ]] && err "Semua kolom wajib diisi!" && press_enter && return
  id "$USR" &>/dev/null && err "Username sudah ada!" && press_enter && return
  local EXP=$(date -d "+${DAYS} days" +"%Y-%m-%d")
  useradd -e "$EXP" -s /bin/false -M "$USR" 2>/dev/null
  echo "$USR:$PASS" | chpasswd
  echo "$USR|$PASS|$EXP|$(date +%Y-%m-%d)|${LIM:-0}" >> "$UDB"
  log "Buat SSH: $USR exp=$EXP"
  echo ""
  ok "Akun SSH berhasil dibuat!"
  echo -e "  ${DM}────────────────────────────────────────${NC}"
  printf "  ${CD}%-12s :${NC} ${CW}%s${NC}\n" "Username" "$USR"
  printf "  ${CD}%-12s :${NC} ${CW}%s${NC}\n" "Password" "$PASS"
  printf "  ${CD}%-12s :${NC} ${YL}%s${NC}\n" "Expired" "$EXP"
  printf "  ${CD}%-12s :${NC} ${CB}%s hari${NC}\n" "Masa Aktif" "$DAYS"
  echo -e "  ${DM}────────────────────────────────────────${NC}"
  press_enter
}

_ssh_hapus(){
  header; sub_hdr "HAPUS AKUN SSH"; _ssh_list; echo ""
  read -rp "$(echo -e "  ${CB}Username :${NC} ")" USR
  ! id "$USR" &>/dev/null && err "User tidak ditemukan!" && press_enter && return
  pkill -u "$USR" 2>/dev/null
  userdel -r "$USR" 2>/dev/null
  sed -i "/^$USR|/d" "$UDB"
  ok "$USR berhasil dihapus."; press_enter
}

_ssh_daftar(){
  header; sub_hdr "DAFTAR AKUN SSH"
  printf "  ${CB}%-18s  %-12s  %-12s  %-10s  %s${NC}\n" "USERNAME" "EXPIRED" "DIBUAT" "SISA" "STATUS"
  echo -e "  ${DM}──────────────────────────────────────────────────────────${NC}"
  [[ ! -s "$UDB" ]] && echo -e "  ${DM}(Belum ada akun)${NC}" || {
    local TODAY=$(date +%Y-%m-%d)
    while IFS='|' read -r u p exp cr lim; do
      local ST SISA
      if [[ "$exp" < "$TODAY" ]]; then
        ST="${RD}EXPIRED${NC}"; SISA=0
      else
        SISA=$(( ($(date -d "$exp" +%s)-$(date +%s))/86400 ))
        ST="${GR}AKTIF${NC}"
      fi
      printf "  ${CW}%-18s${NC}  ${YL}%-12s${NC}  ${DM}%-12s${NC}  ${CB}%-10s${NC}  %b\n" \
        "$u" "$exp" "${cr:-?}" "${SISA}hr" "$ST"
    done < "$UDB"
  }
  press_enter
}

_ssh_info(){
  header; sub_hdr "INFO AKUN SSH"; _ssh_list; echo ""
  read -rp "$(echo -e "  ${CB}Username :${NC} ")" USR
  ! id "$USR" &>/dev/null && err "Tidak ditemukan!" && press_enter && return
  local LINE=$(grep "^$USR|" "$UDB")
  IFS='|' read -r u p exp cr lim <<< "$LINE"
  local SISA=$(( ($(date -d "$exp" +%s)-$(date +%s))/86400 ))
  echo ""
  echo -e "  ${DM}────────────────────────────────────────${NC}"
  printf "  ${CD}%-12s :${NC} ${CW}%s${NC}\n" "Username" "$u"
  printf "  ${CD}%-12s :${NC} ${CW}%s${NC}\n" "Password" "$p"
  printf "  ${CD}%-12s :${NC} ${YL}%s ${DM}(sisa %s hari)${NC}\n" "Expired" "$exp" "$SISA"
  printf "  ${CD}%-12s :${NC} ${CB}%s${NC}\n" "Limit IP" "${lim:-0}"
  echo -e "  ${DM}────────────────────────────────────────${NC}"
  press_enter
}

_ssh_panjang(){
  header; sub_hdr "PERPANJANG AKUN SSH"; _ssh_list; echo ""
  read -rp "$(echo -e "  ${CB}Username      :${NC} ")" USR
  read -rp "$(echo -e "  ${CB}Tambah (hari) :${NC} ")" DAYS
  ! id "$USR" &>/dev/null && err "Tidak ditemukan!" && press_enter && return
  local NE=$(date -d "+${DAYS} days" +"%Y-%m-%d")
  chage -E "$NE" "$USR" 2>/dev/null
  sed -i "s/^$USR|\([^|]*\)|\([^|]*\)|/$USR|\1|$NE|/" "$UDB"
  ok "$USR diperpanjang → $NE"; press_enter
}

_ssh_pass(){
  header; sub_hdr "GANTI PASSWORD SSH"; _ssh_list; echo ""
  read -rp "$(echo -e "  ${CB}Username      :${NC} ")" USR
  read -rsp "$(echo -e "  ${CB}Password baru :${NC} ")" NP; echo ""
  ! id "$USR" &>/dev/null && err "Tidak ditemukan!" && press_enter && return
  echo "$USR:$NP" | chpasswd
  sed -i "s/^$USR|[^|]*|/$USR|$NP|/" "$UDB"
  ok "Password $USR diubah."; press_enter
}

_ssh_online(){
  header; sub_hdr "USER SSH ONLINE"
  printf "  ${CB}%-16s  %-10s  %-22s  %s${NC}\n" "USER" "TERMINAL" "WAKTU" "IP"
  echo -e "  ${DM}──────────────────────────────────────────────────────────${NC}"
  who | while read u t d1 d2 rest; do
    printf "  ${CW}%-16s${NC}  ${CD}%-10s${NC}  ${DM}%-22s${NC}  ${GR}%s${NC}\n" \
      "$u" "$t" "$d1 $d2" "$(echo "$rest"|tr -d '()')"
  done
  press_enter
}

_ssh_kick(){
  header; sub_hdr "KICK USER SSH"; _ssh_list; echo ""
  read -rp "$(echo -e "  ${CB}Username :${NC} ")" USR
  pkill -u "$USR" && ok "$USR diputus." || warn "Tidak ada sesi aktif."; press_enter
}

_ssh_lock(){
  header; sub_hdr "LOCK AKUN SSH"; _ssh_list; echo ""
  read -rp "$(echo -e "  ${CB}Username :${NC} ")" USR
  usermod -e 1 "$USR" 2>/dev/null; ok "$USR di-LOCK."; press_enter
}

_ssh_unlock(){
  header; sub_hdr "UNLOCK AKUN SSH"; _ssh_list; echo ""
  read -rp "$(echo -e "  ${CB}Username :${NC} ")" USR
  local EXP=$(grep "^$USR|" "$UDB" | cut -d'|' -f3)
  usermod -e "$EXP" "$USR" 2>/dev/null; ok "$USR di-UNLOCK."; press_enter
}

menu_ssh(){
  while true; do
    header; sub_hdr "MANAJEMEN AKUN SSH"
    local TOT=$(wc -l < "$UDB" 2>/dev/null || echo 0)
    printf "  ${CD}Total akun SSH :${NC} ${CB}${TOT}${NC}\n\n"
    L_TOP
    printf "${DM}║${NC}  ${CB}[ 1]${NC} Buat Akun SSH         ${DM}│${NC}  ${CB}[ 6]${NC} Ganti Password       ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[ 2]${NC} Hapus Akun SSH        ${DM}│${NC}  ${CB}[ 7]${NC} User Online          ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[ 3]${NC} Daftar Akun SSH       ${DM}│${NC}  ${CB}[ 8]${NC} Kick User            ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[ 4]${NC} Info Akun SSH         ${DM}│${NC}  ${CB}[ 9]${NC} Lock Akun            ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[ 5]${NC} Perpanjang Akun       ${DM}│${NC}  ${CB}[10]${NC} Unlock Akun          ${DM}║${NC}\n"
    L_SEP
    printf "${DM}║${NC}  ${CB}[ 0]${NC} Kembali ke Menu Utama                                ${DM}║${NC}\n"
    L_BOT; echo ""
    read -rp "$(echo -e "  ${CB}❯${NC} Pilih [0-10] : ")" CH
    case "$CH" in
      1) _ssh_buat ;;   2) _ssh_hapus ;;   3) _ssh_daftar ;;
      4) _ssh_info ;;   5) _ssh_panjang ;;  6) _ssh_pass ;;
      7) _ssh_online ;; 8) _ssh_kick ;;    9) _ssh_lock ;;
      10) _ssh_unlock ;; 0) return ;;
      *) warn "Pilihan tidak valid"; sleep 1 ;;
    esac
  done
}

# =================================================================
#   MANAJEMEN UDP CUSTOM
# =================================================================

_udpc_list(){
  echo -e "  ${CB}User UDP Custom :${NC}"
  python3 -c "import json;d=json.load(open('/etc/udp-custom/config.json'));[print('  \033[0;90m•\033[0m \033[1;37m'+p+'\033[0m') for p in d.get('auth',{}).get('config',[])]" 2>/dev/null || echo -e "  ${DM}(kosong)${NC}"
}

_udpc_buat(){
  header; sub_hdr "BUAT USER UDP CUSTOM"
  read -rp "$(echo -e "  ${CB}Password       :${NC} ")" PASS
  read -rp "$(echo -e "  ${CB}Expired (hari) :${NC} ")" DAYS
  python3 -c "
import json
with open('/etc/udp-custom/config.json','r') as f: d=json.load(f)
if 'auth' not in d: d['auth']={'mode':'passwords','config':[]}
if '$PASS' not in d['auth']['config']: d['auth']['config'].append('$PASS')
with open('/etc/udp-custom/config.json','w') as f: json.dump(d,f,indent=2)
" 2>/dev/null
  local EXP=$(date -d "+${DAYS:-30} days" +"%Y-%m-%d")
  echo "$PASS|$EXP|$(date +%Y-%m-%d)" >> "$UDPC_DB"
  systemctl restart udp-custom 2>/dev/null
  ok "User UDP Custom dibuat!"
  printf "  ${CD}%-12s :${NC} ${CW}%s${NC}\n" "Password" "$PASS"
  printf "  ${CD}%-12s :${NC} ${YL}%s${NC}\n" "Expired" "$EXP"
  press_enter
}

_udpc_hapus(){
  header; sub_hdr "HAPUS USER UDP CUSTOM"; _udpc_list; echo ""
  read -rp "$(echo -e "  ${CB}Password :${NC} ")" PASS
  python3 -c "
import json
with open('/etc/udp-custom/config.json','r') as f: d=json.load(f)
d['auth']['config']=[p for p in d['auth']['config'] if p!='$PASS']
with open('/etc/udp-custom/config.json','w') as f: json.dump(d,f,indent=2)
" 2>/dev/null
  sed -i "/^$PASS|/d" "$UDPC_DB"
  systemctl restart udp-custom 2>/dev/null
  ok "$PASS dihapus."; press_enter
}

_udpc_daftar(){
  header; sub_hdr "DAFTAR USER UDP CUSTOM"
  printf "  ${CB}%-3s  %-28s  %s${NC}\n" "No" "Password" "Expired"
  echo -e "  ${DM}────────────────────────────────────────────────${NC}"
  local i=1
  python3 -c "import json;d=json.load(open('/etc/udp-custom/config.json'));[print(p) for p in d.get('auth',{}).get('config',[])]" 2>/dev/null | while read P; do
    local E=$(grep "^$P|" "$UDPC_DB" | cut -d'|' -f2 2>/dev/null || echo "-")
    printf "  ${DM}%-3s${NC}  ${CW}%-28s${NC}  ${YL}%s${NC}\n" "$i." "$P" "$E"; ((i++))
  done
  press_enter
}

_udpc_port(){
  local OLD=$(python3 -c "import json;d=json.load(open('/etc/udp-custom/config.json'));print(d.get('listen',':25500').lstrip(':'))" 2>/dev/null || echo "25500")
  read -rp "$(echo -e "  ${CB}Port baru (saat ini: ${CW}$OLD${CB}) :${NC} ")" NEW
  [[ ! "$NEW" =~ ^[0-9]+$ ]] && err "Port tidak valid!" && press_enter && return
  python3 -c "import json;d=json.load(open('/etc/udp-custom/config.json'));d['listen']=':$NEW';json.dump(d,open('/etc/udp-custom/config.json','w'),indent=2)" 2>/dev/null
  systemctl restart udp-custom 2>/dev/null
  ufw allow "$NEW" 2>/dev/null
  ok "Port UDP Custom → $NEW"; press_enter
}

menu_udpc(){
  while true; do
    header; sub_hdr "MANAJEMEN UDP CUSTOM"
    local PORT=$(python3 -c "import json;d=json.load(open('/etc/udp-custom/config.json'));print(d.get('listen',':25500').lstrip(':'))" 2>/dev/null || echo "25500")
    printf "  ${CD}Status :${NC} $(svc_st udp-custom)   ${CD}Port :${NC} ${CB}$PORT${NC}\n\n"
    L_TOP
    printf "${DM}║${NC}  ${CB}[1]${NC} Buat User UDP         ${DM}│${NC}  ${CB}[4]${NC} Info Koneksi          ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[2]${NC} Hapus User UDP        ${DM}│${NC}  ${CB}[5]${NC} Ganti Port            ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[3]${NC} Daftar User UDP       ${DM}│${NC}                               ${DM}║${NC}\n"
    L_SEP
    printf "${DM}║${NC}  ${CB}[0]${NC} Kembali ke Menu Utama                                ${DM}║${NC}\n"
    L_BOT; echo ""
    read -rp "$(echo -e "  ${CB}❯${NC} Pilih [0-5] : ")" CH
    case "$CH" in
      1) _udpc_buat ;; 2) _udpc_hapus ;; 3) _udpc_daftar ;;
      4) header; sub_hdr "INFO UDP CUSTOM"
         local IP=$(get_ip)
         echo -e "  ${CD}Server :${NC} ${CW}$IP${NC}"
         echo -e "  ${CD}Port   :${NC} ${CB}$PORT${NC}  ${DM}(UDP)${NC}"
         press_enter ;;
      5) header; sub_hdr "GANTI PORT UDP CUSTOM"; _udpc_port ;;
      0) return ;;
      *) warn "Tidak valid"; sleep 1 ;;
    esac
  done
}

# =================================================================
#   MANAJEMEN ZIVPN
# =================================================================

_zivpn_list(){
  echo -e "  ${CB}User ZIVPN :${NC}"
  python3 -c "import json;d=json.load(open('/etc/zivpn/config.json'));[print('  \033[0;90m•\033[0m \033[1;37m'+p+'\033[0m') for p in d.get('auth',{}).get('config',[])]" 2>/dev/null || echo -e "  ${DM}(kosong)${NC}"
}

_zivpn_buat(){
  header; sub_hdr "BUAT USER ZIVPN"
  read -rp "$(echo -e "  ${CB}Password       :${NC} ")" PASS
  read -rp "$(echo -e "  ${CB}Expired (hari) :${NC} ")" DAYS
  python3 -c "
import json
with open('/etc/zivpn/config.json','r') as f: d=json.load(f)
if 'auth' not in d: d['auth']={'mode':'passwords','config':[]}
if '$PASS' not in d.get('auth',{}).get('config',[]): d['auth']['config'].append('$PASS')
with open('/etc/zivpn/config.json','w') as f: json.dump(d,f,indent=2)
" 2>/dev/null
  local EXP=$(date -d "+${DAYS:-30} days" +"%Y-%m-%d")
  echo "$PASS|$EXP|$(date +%Y-%m-%d)" >> "$ZIVPN_DB"
  systemctl restart zivpn 2>/dev/null
  ok "User ZIVPN dibuat!"
  printf "  ${CD}%-12s :${NC} ${CW}%s${NC}\n" "Password" "$PASS"
  printf "  ${CD}%-12s :${NC} ${YL}%s${NC}\n" "Expired" "$EXP"
  press_enter
}

_zivpn_hapus(){
  header; sub_hdr "HAPUS USER ZIVPN"; _zivpn_list; echo ""
  read -rp "$(echo -e "  ${CB}Password :${NC} ")" PASS
  python3 -c "
import json
with open('/etc/zivpn/config.json','r') as f: d=json.load(f)
d['auth']['config']=[p for p in d.get('auth',{}).get('config',[]) if p!='$PASS']
with open('/etc/zivpn/config.json','w') as f: json.dump(d,f,indent=2)
" 2>/dev/null
  sed -i "/^$PASS|/d" "$ZIVPN_DB"
  systemctl restart zivpn 2>/dev/null
  ok "$PASS dihapus."; press_enter
}

_zivpn_daftar(){
  header; sub_hdr "DAFTAR USER ZIVPN"
  printf "  ${CB}%-3s  %-28s  %s${NC}\n" "No" "Password" "Expired"
  echo -e "  ${DM}────────────────────────────────────────────────${NC}"
  local i=1
  python3 -c "import json;d=json.load(open('/etc/zivpn/config.json'));[print(p) for p in d.get('auth',{}).get('config',[])]" 2>/dev/null | while read P; do
    local E=$(grep "^$P|" "$ZIVPN_DB" | cut -d'|' -f2 2>/dev/null || echo "-")
    printf "  ${DM}%-3s${NC}  ${CW}%-28s${NC}  ${YL}%s${NC}\n" "$i." "$P" "$E"; ((i++))
  done
  press_enter
}

_zivpn_port(){
  local OLD=$(python3 -c "import json;d=json.load(open('/etc/zivpn/config.json'));print(d.get('listen',':5600').lstrip(':'))" 2>/dev/null || echo "5600")
  read -rp "$(echo -e "  ${CB}Port baru (saat ini: ${CW}$OLD${CB}) :${NC} ")" NEW
  [[ ! "$NEW" =~ ^[0-9]+$ ]] && err "Port tidak valid!" && press_enter && return
  python3 -c "import json;d=json.load(open('/etc/zivpn/config.json'));d['listen']=':$NEW';json.dump(d,open('/etc/zivpn/config.json','w'),indent=2)" 2>/dev/null
  systemctl restart zivpn 2>/dev/null
  ufw allow "$NEW" 2>/dev/null
  ok "Port ZIVPN → $NEW"; press_enter
}

menu_zivpn(){
  while true; do
    header; sub_hdr "MANAJEMEN ZIVPN UDP"
    local PORT=$(python3 -c "import json;d=json.load(open('/etc/zivpn/config.json'));print(d.get('listen',':5600').lstrip(':'))" 2>/dev/null || echo "5600")
    printf "  ${CD}Status :${NC} $(svc_st zivpn)   ${CD}Port :${NC} ${CB}$PORT${NC}  ${DM}(range 5000-9999)${NC}\n\n"
    L_TOP
    printf "${DM}║${NC}  ${CB}[1]${NC} Buat User ZIVPN      ${DM}│${NC}  ${CB}[4]${NC} Info Koneksi          ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[2]${NC} Hapus User ZIVPN     ${DM}│${NC}  ${CB}[5]${NC} Ganti Port            ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[3]${NC} Daftar User ZIVPN    ${DM}│${NC}                               ${DM}║${NC}\n"
    L_SEP
    printf "${DM}║${NC}  ${CB}[0]${NC} Kembali ke Menu Utama                                ${DM}║${NC}\n"
    L_BOT; echo ""
    read -rp "$(echo -e "  ${CB}❯${NC} Pilih [0-5] : ")" CH
    case "$CH" in
      1) _zivpn_buat ;; 2) _zivpn_hapus ;; 3) _zivpn_daftar ;;
      4) header; sub_hdr "INFO ZIVPN"
         local IP=$(get_ip)
         echo -e "  ${CD}Server :${NC} ${CW}$IP${NC}"
         echo -e "  ${CD}Port   :${NC} ${CB}$PORT${NC}  ${DM}(obfs zivpn, range 5000-9999)${NC}"
         press_enter ;;
      5) header; sub_hdr "GANTI PORT ZIVPN"; _zivpn_port ;;
      0) return ;;
      *) warn "Tidak valid"; sleep 1 ;;
    esac
  done
}

# =================================================================
#   MANAJEMEN XRAY
# =================================================================

_xray_get_clients(){
  python3 -c "
import json,sys
try:
  d=json.load(open('$XC'))
  tag=sys.argv[1] if len(sys.argv)>1 else ''
  for ib in d.get('inbounds',[]):
    if ib.get('tag','')==tag:
      cs=ib.get('settings',{}).get('clients',[])
      for c in cs: print(c.get('id') or c.get('password','?'))
except: pass
" "$1" 2>/dev/null
}

_xray_add_client(){
  # _xray_add_client <tag> <uuid_or_pass> <is_trojan>
  local TAG="$1" VAL="$2" IS_TROJAN="${3:-0}"
  python3 -c "
import json
try:
  with open('$XC','r') as f: d=json.load(f)
  for ib in d['inbounds']:
    if ib['tag']=='$TAG':
      cs=ib['settings']['clients']
      if $IS_TROJAN==1:
        cs.append({'password':'$VAL','email':'user@ogh'})
      else:
        cs.append({'id':'$VAL','alterId':0,'email':'user@ogh'})
  with open('$XC','w') as f: json.dump(d,f,indent=2)
except Exception as e: print(e)
" 2>/dev/null
  echo "$TAG|$VAL|$(date +%Y-%m-%d)" >> "$XDB"
  systemctl restart xray 2>/dev/null
}

_xray_show_link(){
  local PROTO="$1" TLS="$2" NET="$3" PORT="$4" PATH_="$5"
  local IP=$(get_dom)
  local UUID="$6"
  echo ""
  echo -e "  ${DM}════════════════════════════════════════════════════════${NC}"
  printf "  ${CD}%-12s :${NC} ${CW}%s${NC}\n" "Protocol" "$PROTO"
  printf "  ${CD}%-12s :${NC} ${CW}%s${NC}\n" "Host/IP" "$IP"
  printf "  ${CD}%-12s :${NC} ${CB}%s${NC}\n" "Port" "$PORT"
  printf "  ${CD}%-12s :${NC} ${CW}%s${NC}\n" "Network" "$NET"
  printf "  ${CD}%-12s :${NC} ${CW}%s${NC}\n" "Security" "$TLS"
  [[ -n "$PATH_" ]] && printf "  ${CD}%-12s :${NC} ${CW}%s${NC}\n" "Path" "$PATH_"
  printf "  ${CD}%-12s :${NC} ${YL}%s${NC}\n" "UUID/Pass" "$UUID"
  echo -e "  ${DM}════════════════════════════════════════════════════════${NC}"
}

menu_xray(){
  while true; do
    header; sub_hdr "MANAJEMEN XRAY — VMess / VLess / Trojan"
    local MUUID=$([[ -f "$PD/xray_master_uuid" ]] && cat "$PD/xray_master_uuid" || echo "-")
    printf "  ${CD}Status :${NC} $(svc_st xray)   ${CD}Master UUID :${NC} ${DM}${MUUID:0:20}...${NC}\n\n"
    L_TOP
    printf "${DM}║${NC}  ${CB}${BD}  ── Tambah User ──────────────────────────────────────${NC}  ${DM}║${NC}\n"
    L_SEP
    printf "${DM}║${NC}  ${CB}[01]${NC} VMess  WS   nTLS :8443   ${DM}│${NC}  ${CB}[05]${NC} VMess  WS   TLS :8553  ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[02]${NC} VMess  TCP  nTLS :1194   ${DM}│${NC}  ${CB}[06]${NC} VMess  TCP  TLS :2083  ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[03]${NC} VLess  WS   nTLS :8444   ${DM}│${NC}  ${CB}[07]${NC} VLess  WS   TLS :8554  ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[04]${NC} Trojan TCP  nTLS :8445   ${DM}│${NC}  ${CB}[08]${NC} Trojan TCP  TLS :8446  ${DM}║${NC}\n"
    L_SEP
    printf "${DM}║${NC}  ${CB}${BD}  ── Kelola ──────────────────────────────────────────${NC}  ${DM}║${NC}\n"
    L_SEP
    printf "${DM}║${NC}  ${CB}[09]${NC} Daftar User Xray         ${DM}│${NC}  ${CB}[12]${NC} Info Link VMess       ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[10]${NC} Hapus User Xray          ${DM}│${NC}  ${CB}[13]${NC} Info Link VLess       ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[11]${NC} Restart Xray             ${DM}│${NC}  ${CB}[14]${NC} Info Link Trojan      ${DM}║${NC}\n"
    L_SEP
    printf "${DM}║${NC}  ${CB}[00]${NC} Kembali ke Menu Utama                                ${DM}║${NC}\n"
    L_BOT; echo ""
    read -rp "$(echo -e "  ${CB}❯${NC} Pilih [00-14] : ")" CH
    case "$CH" in
      01|1) _xr_tambah vmess-ws    vmess ws  8443 /vmess 0 ;;
      02|2) _xr_tambah vmess-tcp   vmess tcp 1194 ""     0 ;;
      03|3) _xr_tambah vless-ws    vless ws  8444 /vless 0 ;;
      04|4) _xr_tambah trojan      trojan tcp 8445 ""    1 ;;
      05|5) _xr_tambah vmess-ws-tls    vmess ws  8553 /vmess-tls 0 ;;
      06|6) _xr_tambah vmess-tcp-tls   vmess tcp 2083 ""          0 ;;
      07|7) _xr_tambah vless-ws-tls    vless ws  8554 /vless-tls  0 ;;
      08|8) _xr_tambah trojan-tls      trojan tcp 8446 ""         1 ;;
      09|9) _xr_daftar ;;
      10)   _xr_hapus ;;
      11)   systemctl restart xray 2>/dev/null; ok "Xray di-restart."; sleep 1 ;;
      12)   _xr_info_link vmess ;;
      13)   _xr_info_link vless ;;
      14)   _xr_info_link trojan ;;
      00|0) return ;;
      *) warn "Tidak valid"; sleep 1 ;;
    esac
  done
}

_xr_tambah(){
  local TAG="$1" PROTO="$2" NET="$3" PORT="$4" PATH_="$5" IS_TROJAN="$6"
  header; sub_hdr "TAMBAH USER $PROTO (port $PORT)"
  local VAL
  if [[ "$IS_TROJAN" == "1" ]]; then
    read -rp "$(echo -e "  ${CB}Password :${NC} ")" VAL
  else
    VAL=$(gen_uuid)
    echo -e "  ${CB}UUID baru :${NC} ${CW}$VAL${NC}"
    read -rp "$(echo -e "  ${CB}Email/catatan :${NC} ")" EMAIL
  fi
  _xray_add_client "$TAG" "$VAL" "$IS_TROJAN"
  ok "User berhasil ditambahkan!"
  _xray_show_link "$PROTO" "$([[ $PORT =~ 8553|2083|8554|8446 ]] && echo tls || echo none)" "$NET" "$PORT" "$PATH_" "$VAL"
  press_enter
}

_xr_daftar(){
  header; sub_hdr "DAFTAR USER XRAY"
  printf "  ${CB}%-3s  %-20s  %-30s  %s${NC}\n" "No" "Tag/Protokol" "UUID/Password" "Tanggal"
  echo -e "  ${DM}────────────────────────────────────────────────────────────${NC}"
  [[ ! -s "$XDB" ]] && echo -e "  ${DM}(Belum ada user)${NC}" || {
    local i=1
    while IFS='|' read -r tag val date; do
      printf "  ${DM}%-3s${NC}  ${CD}%-20s${NC}  ${CW}%-30s${NC}  ${DM}%s${NC}\n" \
        "$i." "${tag:0:20}" "${val:0:28}" "$date"; ((i++))
    done < "$XDB"
  }
  press_enter
}

_xr_hapus(){
  header; sub_hdr "HAPUS USER XRAY"; _xr_daftar
  read -rp "$(echo -e "  ${CB}Masukkan UUID/Password :${NC} ")" VAL
  sed -i "/|$VAL|/d" "$XDB"
  python3 -c "
import json
with open('$XC','r') as f: d=json.load(f)
for ib in d['inbounds']:
  cs=ib.get('settings',{}).get('clients',[])
  ib['settings']['clients']=[c for c in cs if c.get('id')!='$VAL' and c.get('password')!='$VAL']
with open('$XC','w') as f: json.dump(d,f,indent=2)
" 2>/dev/null
  systemctl restart xray 2>/dev/null
  ok "User dihapus."; press_enter
}

_xr_info_link(){
  local PROTO="$1"
  header; sub_hdr "INFO LINK $PROTO"
  local IP=$(get_dom)
  local MUUID=$([[ -f "$PD/xray_master_uuid" ]] && cat "$PD/xray_master_uuid" || echo "?")
  case "$PROTO" in
    vmess)
      echo -e "\n  ${CB}VMess WS  nTLS :8443${NC}"
      echo -e "  ${CD}Host:${NC} $IP  ${CD}UUID:${NC} $MUUID  ${CD}Path:${NC} /vmess"
      echo -e "\n  ${CB}VMess WS  TLS  :8553${NC}"
      echo -e "  ${CD}Host:${NC} $IP  ${CD}UUID:${NC} $MUUID  ${CD}Path:${NC} /vmess-tls"
      echo -e "\n  ${CB}VMess TCP nTLS :1194${NC}"
      echo -e "  ${CD}Host:${NC} $IP  ${CD}UUID:${NC} $MUUID"
      echo -e "\n  ${CB}VMess TCP TLS  :2083${NC}"
      echo -e "  ${CD}Host:${NC} $IP  ${CD}UUID:${NC} $MUUID"
      ;;
    vless)
      echo -e "\n  ${CB}VLess WS  nTLS :8444${NC}"
      echo -e "  ${CD}Host:${NC} $IP  ${CD}UUID:${NC} $MUUID  ${CD}Path:${NC} /vless"
      echo -e "\n  ${CB}VLess WS  TLS  :8554${NC}"
      echo -e "  ${CD}Host:${NC} $IP  ${CD}UUID:${NC} $MUUID  ${CD}Path:${NC} /vless-tls"
      ;;
    trojan)
      echo -e "\n  ${CB}Trojan TCP nTLS :8445${NC}"
      echo -e "  ${CD}Host:${NC} $IP  ${CD}Pass:${NC} ogh-trojan"
      echo -e "\n  ${CB}Trojan TCP TLS  :8446${NC}"
      echo -e "  ${CD}Host:${NC} $IP  ${CD}Pass:${NC} ogh-trojan"
      ;;
  esac
  press_enter
}

# =================================================================
#   KELOLA SERVICE
# =================================================================

menu_service(){
  while true; do
    header; sub_hdr "KELOLA SERVICE"
    printf "  ${CD}%-20s${NC} %b    ${CD}%-20s${NC} %b\n" "SSH"       "$(svc_st ssh)"       "Dropbear"    "$(svc_st dropbear)"
    printf "  ${CD}%-20s${NC} %b    ${CD}%-20s${NC} %b\n" "Stunnel4"  "$(svc_st stunnel4)"  "UDP Custom"  "$(svc_st udp-custom)"
    printf "  ${CD}%-20s${NC} %b    ${CD}%-20s${NC} %b\n" "WS SSH:80" "$(svc_st ws-ssh-80)" "ZIVPN"       "$(svc_st zivpn)"
    printf "  ${CD}%-20s${NC} %b    ${CD}%-20s${NC} %b\n" "Xray"      "$(svc_st xray)"      "BadVPN:7300" "$(svc_st badvpn-7300)"
    printf "  ${CD}%-20s${NC} %b\n" "Squid"     "$(svc_st squid)"
    echo ""
    L_TOP
    printf "${DM}║${NC}  ${CB}[1]${NC} Restart Semua Service                                 ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[2]${NC} Start Semua Service                                   ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[3]${NC} Stop Semua Service (kecuali SSH)                      ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[4]${NC} Restart Satu Service                                  ${DM}║${NC}\n"
    L_SEP
    printf "${DM}║${NC}  ${CB}[0]${NC} Kembali ke Menu Utama                                 ${DM}║${NC}\n"
    L_BOT; echo ""
    read -rp "$(echo -e "  ${CB}❯${NC} Pilih [0-4] : ")" CH
    case "$CH" in
      1) _svc_restart_all ;;
      2) _svc_start_all ;;
      3) _svc_stop_all ;;
      4) _svc_restart_one ;;
      0) return ;;
      *) warn "Tidak valid"; sleep 1 ;;
    esac
  done
}

_svc_list=(ssh dropbear stunnel4 ws-ssh-80 ws-ssh-8880 ws-ssh-8008
           xray udp-custom zivpn badvpn-7100 badvpn-7200 badvpn-7300 squid)

_svc_restart_all(){
  echo ""
  for S in "${_svc_list[@]}"; do
    systemctl restart "$S" 2>/dev/null
    printf "  %-25s %b\n" "$S" "$(svc_st $S)"
  done
  ok "Semua service di-restart."; press_enter
}

_svc_start_all(){
  echo ""
  for S in "${_svc_list[@]}"; do
    systemctl start "$S" 2>/dev/null
    printf "  %-25s %b\n" "$S" "$(svc_st $S)"
  done
  ok "Semua service distart."; press_enter
}

_svc_stop_all(){
  echo ""
  for S in stunnel4 ws-ssh-80 ws-ssh-8880 ws-ssh-8008 \
            xray udp-custom zivpn badvpn-7100 badvpn-7200 badvpn-7300 squid; do
    systemctl stop "$S" 2>/dev/null
    printf "  %-25s %b\n" "$S" "$(svc_st $S)"
  done
  warn "SSH tetap aktif."; press_enter
}

_svc_restart_one(){
  echo ""
  echo -e "  ${CB}Service yang tersedia:${NC}"
  local i=1
  for S in "${_svc_list[@]}"; do printf "  ${DM}%2s.${NC} %s\n" "$i" "$S"; ((i++)); done
  echo ""
  read -rp "$(echo -e "  ${CB}Nama service :${NC} ")" SVC
  systemctl restart "$SVC" 2>/dev/null && ok "$SVC di-restart." || err "Service tidak ditemukan."
  press_enter
}

# =================================================================
#   INFO SERVER
# =================================================================

_show_all_info(){
  header; sub_hdr "INFO LENGKAP SERVER & PORT"
  local IP=$(get_ip)
  local DOM=$(get_dom)
  echo ""
  echo -e "  ${CB}${BD}── SSH & Dropbear ────────────────────────────────────${NC}"
  printf "  ${CD}%-25s :${NC} ${CW}%s${NC}\n" "SSH"             "$IP:22, $IP:2222"
  printf "  ${CD}%-25s :${NC} ${CW}%s${NC}\n" "Dropbear"        "$IP:69, $IP:109, $IP:143"
  printf "  ${CD}%-25s :${NC} ${CW}%s${NC}\n" "Stunnel4 SSL"    "$IP:443(DB), $IP:444(SSH), $IP:777(SSH)"
  printf "  ${CD}%-25s :${NC} ${CW}%s${NC}\n" "WebSocket SSH"   "$IP:80, $IP:8880, $IP:8008"
  echo ""
  echo -e "  ${CB}${BD}── Xray ─────────────────────────────────────────────${NC}"
  printf "  ${CD}%-25s :${NC} ${CW}%s${NC}\n" "VMess WS nTLS"   "$IP:8443  path=/vmess"
  printf "  ${CD}%-25s :${NC} ${CW}%s${NC}\n" "VMess WS TLS"    "$IP:8553  path=/vmess-tls"
  printf "  ${CD}%-25s :${NC} ${CW}%s${NC}\n" "VMess TCP nTLS"  "$IP:1194"
  printf "  ${CD}%-25s :${NC} ${CW}%s${NC}\n" "VMess TCP TLS"   "$IP:2083"
  printf "  ${CD}%-25s :${NC} ${CW}%s${NC}\n" "VLess WS nTLS"   "$IP:8444  path=/vless"
  printf "  ${CD}%-25s :${NC} ${CW}%s${NC}\n" "VLess WS TLS"    "$IP:8554  path=/vless-tls"
  printf "  ${CD}%-25s :${NC} ${CW}%s${NC}\n" "Trojan TCP nTLS" "$IP:8445"
  printf "  ${CD}%-25s :${NC} ${CW}%s${NC}\n" "Trojan TCP TLS"  "$IP:8446"
  echo ""
  echo -e "  ${CB}${BD}── UDP ──────────────────────────────────────────────${NC}"
  printf "  ${CD}%-25s :${NC} ${CW}%s${NC}\n" "UDP Custom"      "$IP:25500 (UDP)"
  printf "  ${CD}%-25s :${NC} ${CW}%s${NC}\n" "ZIVPN UDP"       "$IP:5600  (obfs zivpn, 5000-9999)"
  printf "  ${CD}%-25s :${NC} ${CW}%s${NC}\n" "BadVPN UDPGW"    "127.0.0.1:7100, 7200, 7300"
  echo ""
  echo -e "  ${CB}${BD}── Proxy ────────────────────────────────────────────${NC}"
  printf "  ${CD}%-25s :${NC} ${CW}%s${NC}\n" "Squid Proxy"     "$IP:3128, $IP:8080"
  echo ""
  press_enter
}

# =================================================================
#   MONITOR SERVER
# =================================================================

menu_monitor(){
  while true; do
    header; sub_hdr "MONITOR SERVER"
    echo ""
    local CPU=$(top -bn1 2>/dev/null | grep 'Cpu(s)' | awk '{printf "%.2f%%",$2+$4}')
    local RAM_U=$(free -m | awk '/^Mem:/{print $3}')
    local RAM_T=$(free -m | awk '/^Mem:/{print $2}')
    local RAM_P=$(awk "BEGIN{printf \"%.1f\",($RAM_U/$RAM_T)*100}")
    local DISK=$(df -h / | awk 'NR==2{print $3"/"$2" ("$5")"}')
    local CONN=$(ss -tnp | grep -c ESTAB || echo 0)
    local NET_RX=$(cat /proc/net/dev | grep -E "eth0|ens" | head -1 | awk '{printf "%.1f MB",$2/1048576}')
    local NET_TX=$(cat /proc/net/dev | grep -E "eth0|ens" | head -1 | awk '{printf "%.1f MB",$10/1048576}')

    printf "  ${CD}%-20s :${NC} ${CB}%s${NC}\n" "CPU Usage"  "$CPU"
    printf "  ${CD}%-20s :${NC} ${CB}%s MB / %s MB (%.1f%%)${NC}\n" "RAM" "$RAM_U" "$RAM_T" "$RAM_P"
    printf "  ${CD}%-20s :${NC} ${CB}%s${NC}\n" "Disk /"     "$DISK"
    printf "  ${CD}%-20s :${NC} ${CB}%s${NC}\n" "Koneksi"    "$CONN aktif"
    printf "  ${CD}%-20s :${NC} ${CB}%s${NC}\n" "Network RX" "$NET_RX"
    printf "  ${CD}%-20s :${NC} ${CB}%s${NC}\n" "Network TX" "$NET_TX"
    echo ""
    printf "  ${CD}%-20s :${NC} $(svc_dot ssh)    ${CD}%-15s :${NC} $(svc_dot xray)\n"      "SSH/Dropbear" "Xray"
    printf "  ${CD}%-20s :${NC} $(svc_dot udp-custom) ${CD}%-15s :${NC} $(svc_dot zivpn)\n" "UDP Custom" "ZIVPN"
    printf "  ${CD}%-20s :${NC} $(svc_dot stunnel4)  ${CD}%-15s :${NC} $(svc_dot ws-ssh-80)\n" "Stunnel4" "WebSocket"
    echo ""
    L_TOP
    printf "${DM}║${NC}  ${CB}[1]${NC} Refresh    ${CB}[2]${NC} Top proses    ${CB}[3]${NC} Netstat    ${CB}[0]${NC} Kembali  ${DM}║${NC}\n"
    L_BOT; echo ""
    read -rp "$(echo -e "  ${CB}❯${NC} Pilih [0-3] : ")" CH
    case "$CH" in
      1) continue ;;
      2) top ;;
      3) ss -tnp | head -30; press_enter ;;
      0) return ;;
      *) warn "Tidak valid"; sleep 1 ;;
    esac
  done
}

# =================================================================
#   LOG & RIWAYAT
# =================================================================

menu_log(){
  while true; do
    header; sub_hdr "LOG & RIWAYAT"
    L_TOP
    printf "${DM}║${NC}  ${CB}[1]${NC} Log Panel OGH           ${DM}│${NC}  ${CB}[4]${NC} Log Xray Access       ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[2]${NC} Log SSH (auth)          ${DM}│${NC}  ${CB}[5]${NC} Log Xray Error        ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[3]${NC} Log System              ${DM}│${NC}  ${CB}[6]${NC} Hapus Log Panel       ${DM}║${NC}\n"
    L_SEP
    printf "${DM}║${NC}  ${CB}[0]${NC} Kembali ke Menu Utama                                 ${DM}║${NC}\n"
    L_BOT; echo ""
    read -rp "$(echo -e "  ${CB}❯${NC} Pilih [0-6] : ")" CH
    case "$CH" in
      1) less "$LOG_FILE" 2>/dev/null || echo "(Log kosong)" ;;
      2) tail -50 /var/log/auth.log 2>/dev/null || journalctl -u ssh -n 50; press_enter ;;
      3) journalctl -n 50; press_enter ;;
      4) tail -50 /var/log/xray/access.log 2>/dev/null || echo "(Log xray kosong)"; press_enter ;;
      5) tail -50 /var/log/xray/error.log  2>/dev/null || echo "(Log xray kosong)"; press_enter ;;
      6) > "$LOG_FILE"; ok "Log panel dihapus."; press_enter ;;
      0) return ;;
      *) warn "Tidak valid"; sleep 1 ;;
    esac
  done
}

# =================================================================
#   PENGATURAN PANEL
# =================================================================

menu_setting(){
  while true; do
    header; sub_hdr "PENGATURAN PANEL"
    L_TOP
    printf "${DM}║${NC}  ${CB}[1]${NC} Ubah Port SSH           ${DM}│${NC}  ${CB}[6]${NC} Auto Kill Akun       ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[2]${NC} Ubah Port Dropbear      ${DM}│${NC}  ${CB}[7]${NC} Backup Konfigurasi   ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[3]${NC} Setup Domain            ${DM}│${NC}  ${CB}[8]${NC} Restore Konfigurasi  ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[4]${NC} Renew SSL Xray          ${DM}│${NC}  ${CB}[9]${NC} Update Panel         ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[5]${NC} Auto Reboot             ${DM}│${NC}                               ${DM}║${NC}\n"
    L_SEP
    printf "${DM}║${NC}  ${CB}[0]${NC} Kembali ke Menu Utama                                 ${DM}║${NC}\n"
    L_BOT; echo ""
    read -rp "$(echo -e "  ${CB}❯${NC} Pilih [0-9] : ")" CH
    case "$CH" in
      1) _set_port_ssh ;;
      2) _set_port_db ;;
      3) _set_domain ;;
      4) _renew_ssl ;;
      5) _set_autoreboot ;;
      6) _set_autokill ;;
      7) _backup ;;
      8) _restore ;;
      9) _update_panel ;;
      0) return ;;
      *) warn "Tidak valid"; sleep 1 ;;
    esac
  done
}

_set_port_ssh(){
  header; sub_hdr "UBAH PORT SSH"
  local CUR=$(grep "^Port " /etc/ssh/sshd_config | tr '\n' ' ')
  echo -e "  ${CD}Port saat ini :${NC} ${CB}$CUR${NC}"
  read -rp "$(echo -e "  ${CB}Port utama baru :${NC} ")" P1
  read -rp "$(echo -e "  ${CB}Port tambahan   :${NC} ")" P2
  [[ ! "$P1" =~ ^[0-9]+$ ]] && err "Port tidak valid!" && press_enter && return
  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
  sed -i '/^Port /d' /etc/ssh/sshd_config
  echo "Port $P1" >> /etc/ssh/sshd_config
  [[ "$P2" =~ ^[0-9]+$ ]] && echo "Port $P2" >> /etc/ssh/sshd_config
  sshd -t 2>/dev/null || { err "Config SSH error! Rollback..."; cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config; press_enter; return; }
  ufw allow "$P1" 2>/dev/null
  [[ "$P2" =~ ^[0-9]+$ ]] && ufw allow "$P2" 2>/dev/null
  systemctl restart ssh 2>/dev/null
  ok "Port SSH → $P1 ${P2:+& $P2}"; press_enter
}

_set_port_db(){
  header; sub_hdr "UBAH PORT DROPBEAR"
  local CUR=$(grep "^DROPBEAR_PORT=" /etc/default/dropbear | cut -d= -f2)
  echo -e "  ${CD}Port saat ini :${NC} ${CB}$CUR${NC}"
  read -rp "$(echo -e "  ${CB}Port utama baru :${NC} ")" P
  [[ ! "$P" =~ ^[0-9]+$ ]] && err "Port tidak valid!" && press_enter && return
  sed -i "s/^DROPBEAR_PORT=.*/DROPBEAR_PORT=$P/" /etc/default/dropbear
  ufw allow "$P" 2>/dev/null
  systemctl restart dropbear 2>/dev/null
  ok "Port Dropbear → $P"; press_enter
}

_set_domain(){
  header; sub_hdr "SETUP DOMAIN"
  local CUR=$(get_dom)
  echo -e "  ${CD}Domain/IP saat ini :${NC} ${CB}$CUR${NC}"
  read -rp "$(echo -e "  ${CB}Domain baru (kosong=skip) :${NC} ")" DOM
  [[ -n "$DOM" ]] && echo "$DOM" > "$DOMAIN_FILE" && ok "Domain → $DOM" || warn "Tidak ada perubahan."
  press_enter
}

_renew_ssl(){
  header; sub_hdr "RENEW SSL XRAY"
  info "Membuat sertifikat SSL baru..."
  local DOM=$(get_dom)
  openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
    -subj "/C=ID/O=OGH/CN=$DOM" \
    -keyout "$XD/xray.key" -out "$XD/xray.crt" 2>/dev/null
  systemctl restart xray 2>/dev/null
  ok "SSL Xray diperbarui (self-signed, 10 tahun)."
  press_enter
}

_set_autoreboot(){
  header; sub_hdr "AUTO REBOOT"
  local CUR=$(crontab -l 2>/dev/null | grep "auto-reboot")
  [[ -n "$CUR" ]] && echo -e "  ${CD}Jadwal saat ini :${NC} ${YL}$CUR${NC}" || echo -e "  ${CD}Auto reboot :${NC} ${RD}Belum aktif${NC}"
  echo ""
  L_TOP
  printf "${DM}║${NC}  ${CB}[1]${NC} Set Auto Reboot Setiap Hari                           ${DM}║${NC}\n"
  printf "${DM}║${NC}  ${CB}[2]${NC} Hapus Auto Reboot                                     ${DM}║${NC}\n"
  printf "${DM}║${NC}  ${CB}[0]${NC} Kembali                                               ${DM}║${NC}\n"
  L_BOT; echo ""
  read -rp "$(echo -e "  ${CB}❯${NC} Pilih : ")" CH
  case "$CH" in
    1) read -rp "$(echo -e "  ${CB}Jam reboot (0-23) :${NC} ")" HR
       (crontab -l 2>/dev/null | grep -v "auto-reboot"; echo "0 $HR * * * reboot # auto-reboot") | crontab -
       ok "Auto reboot setiap jam $HR:00 diatur." ;;
    2) (crontab -l 2>/dev/null | grep -v "auto-reboot") | crontab -; ok "Auto reboot dinonaktifkan." ;;
  esac
  press_enter
}

_set_autokill(){
  header; sub_hdr "AUTO KILL AKUN EXPIRED"
  info "Memeriksa dan menghapus akun expired..."
  local TODAY=$(date +%Y-%m-%d)
  local KILLED=0
  while IFS='|' read -r u p exp _; do
    if [[ "$exp" < "$TODAY" ]]; then
      pkill -u "$u" 2>/dev/null
      userdel -r "$u" 2>/dev/null
      sed -i "/^$u|/d" "$UDB"
      warn "Akun $u ($exp) dihapus."
      ((KILLED++))
    fi
  done < "$UDB"
  [[ $KILLED -eq 0 ]] && ok "Tidak ada akun expired." || ok "$KILLED akun expired dihapus."
  press_enter
}

_backup(){
  header; sub_hdr "BACKUP KONFIGURASI"
  local BFILE="$PD/backup/backup-$(date +%Y%m%d-%H%M%S).tar.gz"
  tar czf "$BFILE" \
    "$UDB" "$UDPC_DB" "$ZIVPN_DB" "$XDB" "$LOG_FILE" \
    /etc/ssh/sshd_config /etc/default/dropbear \
    /etc/stunnel/stunnel.conf "$XC" 2>/dev/null
  ok "Backup tersimpan: ${CW}$BFILE${NC}"
  press_enter
}

_restore(){
  header; sub_hdr "RESTORE KONFIGURASI"
  echo -e "  ${CB}File backup tersedia:${NC}"
  ls -1 "$PD/backup/"*.tar.gz 2>/dev/null || { warn "Tidak ada backup."; press_enter; return; }
  echo ""
  read -rp "$(echo -e "  ${CB}Nama file backup :${NC} ")" BFILE
  [[ ! -f "$BFILE" ]] && err "File tidak ditemukan!" && press_enter && return
  tar xzf "$BFILE" -C / 2>/dev/null
  ok "Restore selesai. Restart service..."; systemctl restart ssh dropbear xray 2>/dev/null
  press_enter
}

_update_panel(){
  header; sub_hdr "UPDATE PANEL"
  read -rp "$(echo -e "  ${CB}URL script baru :${NC} ")" URL
  [[ -z "$URL" ]] && warn "URL kosong." && press_enter && return
  local SELF=$(readlink -f "$0")
  wget -q "$URL" -O "$SELF" 2>/dev/null && chmod +x "$SELF" && ok "Panel diupdate! Jalankan ulang." \
    || err "Gagal download dari URL tersebut."
  press_enter
}

# =================================================================
#   SPEEDTEST
# =================================================================

menu_speedtest(){
  header; sub_hdr "SPEEDTEST VPS"
  echo ""
  L_TOP
  printf "${DM}║${NC}  ${CB}[1]${NC} speedtest-cli (pip)                                    ${DM}║${NC}\n"
  printf "${DM}║${NC}  ${CB}[2]${NC} Download test (wget 100MB)                             ${DM}║${NC}\n"
  printf "${DM}║${NC}  ${CB}[3]${NC} Upload test (dd + curl)                                ${DM}║${NC}\n"
  L_SEP
  printf "${DM}║${NC}  ${CB}[0]${NC} Kembali ke Menu Utama                                  ${DM}║${NC}\n"
  L_BOT; echo ""
  read -rp "$(echo -e "  ${CB}❯${NC} Pilih [0-3] : ")" CH
  case "$CH" in
    1) command -v speedtest-cli &>/dev/null || pip3 install speedtest-cli -q 2>/dev/null
       speedtest-cli --simple 2>/dev/null || warn "speedtest-cli gagal." ;;
    2) info "Download test 100MB..."
       wget -O /dev/null --progress=dot:mega http://speedtest.tele2.net/100MB.zip 2>&1 \
         | grep -Eo '[0-9]+(\.[0-9]+)? [KMG]B/s' | tail -1 | xargs -I{} echo -e "  ${GR}Kecepatan Download: {}${NC}" ;;
    3) info "Upload test..."
       dd if=/dev/urandom bs=1M count=10 2>/dev/null | curl -s -o /dev/null \
         -w "  Upload: %{speed_upload} bytes/s\n" --data-binary @- https://httpbin.org/post 2>/dev/null ;;
    0) return ;;
  esac
  press_enter
}

# =================================================================
#   MAIN MENU
# =================================================================

main_menu(){
  check_root

  # Init direktori & file
  mkdir -p "$PD/backup" "$XD"
  touch "$UDB" "$UDPC_DB" "$ZIVPN_DB" "$XDB" "$LOG_FILE" 2>/dev/null

  # ── AUTO INSTALL PERTAMA KALI ─────────────────────────────
  if [[ ! -f "$FLAG" ]]; then
    clear
    show_logo
    echo -e "${CB}  Pertama kali dijalankan — memulai instalasi otomatis...${NC}"
    echo ""
    do_auto_install
  fi

  # ── LOOP MENU UTAMA ───────────────────────────────────────
  while true; do
    header

    # Status layanan
    L_TOP
    printf "${DM}║${NC}  ${CB}${BD}  STATUS LAYANAN                                          ${NC}${DM}║${NC}\n"
    L_MID
    printf "${DM}║${NC}  $(svc_dot ssh)  ${CD}SSH/Dropbear   ${NC}$(svc_st ssh)    ${DM}│${NC}  $(svc_dot udp-custom)  ${CD}UDP Custom    ${NC}$(svc_st udp-custom)  ${DM}║${NC}\n"
    printf "${DM}║${NC}  $(svc_dot stunnel4)  ${CD}Stunnel4 SSL   ${NC}$(svc_st stunnel4)    ${DM}│${NC}  $(svc_dot zivpn)  ${CD}ZIVPN UDP     ${NC}$(svc_st zivpn)  ${DM}║${NC}\n"
    printf "${DM}║${NC}  $(svc_dot ws-ssh-80)  ${CD}WebSocket SSH  ${NC}$(svc_st ws-ssh-80)    ${DM}│${NC}  $(svc_dot xray)  ${CD}Xray V2Ray    ${NC}$(svc_st xray)  ${DM}║${NC}\n"
    printf "${DM}║${NC}  $(svc_dot badvpn-7300)  ${CD}BadVPN UDPGW   ${NC}$(svc_st badvpn-7300)    ${DM}│${NC}  $(svc_dot squid)  ${CD}Squid Proxy   ${NC}$(svc_st squid)  ${DM}║${NC}\n"
    L_BOT
    echo ""

    # Menu Utama
    L_TOP
    printf "${DM}║${NC}  ${CB}${BD}  MENU UTAMA                                              ${NC}${DM}║${NC}\n"
    L_MID
    printf "${DM}║${NC}  ${CB}[ 1]${NC} Manajemen SSH           ${DM}│${NC}  ${CB}[ 7]${NC} Monitor Server         ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[ 2]${NC} Manajemen UDP Custom    ${DM}│${NC}  ${CB}[ 8]${NC} Info Server & Port      ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[ 3]${NC} Manajemen ZIVPN UDP     ${DM}│${NC}  ${CB}[ 9]${NC} Log & Riwayat          ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[ 4]${NC} Manajemen Xray          ${DM}│${NC}  ${CB}[10]${NC} Pengaturan Panel        ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CD}      VMess/VLess/Trojan  ${DM}│${NC}  ${CB}[11]${NC} Speedtest VPS           ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[ 5]${NC} Kelola Service          ${DM}│${NC}                                ${DM}║${NC}\n"
    printf "${DM}║${NC}  ${CB}[ 6]${NC} Info Server Lengkap     ${DM}│${NC}                                ${DM}║${NC}\n"
    L_SEP
    printf "${DM}║${NC}  ${CB}[ 0]${NC} ${CW}Keluar dari Panel                                      ${NC}${DM}║${NC}\n"
    L_BOT
    echo ""
    read -rp "$(echo -e "  ${CB}❯${NC} Pilih Menu [0-11] : ")" M

    case "$M" in
      1)  menu_ssh ;;
      2)  menu_udpc ;;
      3)  menu_zivpn ;;
      4)  menu_xray ;;
      5)  menu_service ;;
      6)  _show_all_info ;;
      7)  menu_monitor ;;
      8)  _show_all_info ;;
      9)  menu_log ;;
      10) menu_setting ;;
      11) menu_speedtest ;;
      0)  clear
          echo -e "\n${CB}  OGH-PANELL v4.1 — Sampai jumpa!${NC}"
          echo -e "${CD}  Ketik ${CW}menu${CD} untuk membuka panel kembali.${NC}\n"
          exit 0 ;;
      *)  warn "Pilihan tidak valid!"; sleep 1 ;;
    esac
  done
}

main_menu
