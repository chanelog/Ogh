#!/bin/bash
# ================================================================
#   UDPserver Manager
#   Bahasa   : Indonesia
#   Binary   : https://github.com/chanelog/Ogh/raw/refs/heads/main/udpServer
#   Support  : Debian 9/10/11/12 | Ubuntu 18.04/20.04/22.04/24.04
#   All Region VPS Compatible
# ================================================================

udp_file='/etc/UDPserver'
BIN_URL='https://github.com/chanelog/Ogh/raw/refs/heads/main/udpServer'
SERVICE='/etc/systemd/system/UDPserver.service'

# ================================================================
# MODUL WARNA & UI
# ================================================================

msg(){
  COLOR[0]='\033[1;37m'
  COLOR[1]='\e[31m'
  COLOR[2]='\e[32m'
  COLOR[3]='\e[33m'
  COLOR[4]='\e[34m'
  COLOR[5]='\e[91m'
  COLOR[6]='\033[1;97m'
  COLOR[7]='\e[36m'
  COLOR[8]='\e[30m'
  COLOR[9]='\033[34m'
  NEGRITO='\e[1m'
  SEMCOR='\e[0m'
  case $1 in
    -ne)   cor="${COLOR[1]}${NEGRITO}" && echo -ne "${cor}${2}${SEMCOR}";;
    -nazu) cor="${COLOR[6]}${NEGRITO}" && echo -ne "${cor}${2}${SEMCOR}";;
    -nverd)cor="${COLOR[2]}${NEGRITO}" && echo -ne "${cor}${2}${SEMCOR}";;
    -nama) cor="${COLOR[3]}${NEGRITO}" && echo -ne "${cor}${2}${SEMCOR}";;
    -ama)  cor="${COLOR[3]}${NEGRITO}" && echo -e  "${cor}${2}${SEMCOR}";;
    -verm) cor="${COLOR[3]}${NEGRITO}[!] ${COLOR[1]}" && echo -e "${cor}${2}${SEMCOR}";;
    -verm2)cor="${COLOR[1]}${NEGRITO}" && echo -e  "${cor}${2}${SEMCOR}";;
    -verm3)cor="${COLOR[1]}"           && echo -e  "${cor}${2}${SEMCOR}";;
    -teal) cor="${COLOR[7]}${NEGRITO}" && echo -e  "${cor}${2}${SEMCOR}";;
    -azu)  cor="${COLOR[6]}${NEGRITO}" && echo -e  "${cor}${2}${SEMCOR}";;
    -blu)  cor="${COLOR[9]}${NEGRITO}" && echo -e  "${cor}${2}${SEMCOR}";;
    -verd) cor="${COLOR[2]}${NEGRITO}" && echo -e  "${cor}${2}${SEMCOR}";;
    -bra)  cor="${COLOR[0]}${NEGRITO}" && echo -e  "${cor}${2}${SEMCOR}";;
    -bar)  echo -e "\e[31m=====================================================\e[0m";;
    -bar2) echo -e "\e[36m=====================================================\e[0m";;
    -bar3) echo -e "\e[31m-----------------------------------------------------\e[0m";;
    -bar4) echo -e "\e[36m-----------------------------------------------------\e[0m";;
  esac
}

print_center(){
  if [[ -z $2 ]]; then
    text="$1"; col=""
  else
    col="$1"; text="$2"
  fi
  while IFS= read -r line; do
    unset space
    # Hapus escape code untuk hitung panjang asli
    plain=$(echo -e "$line" | sed 's/\x1B\[[0-9;]*[mK]//g')
    x=$(( ( 54 - ${#plain} ) / 2 ))
    for (( i = 0; i < x; i++ )); do space+=' '; done
    space+="$line"
    if [[ -z $col ]]; then
      msg -azu "$space"
    else
      msg "$col" "$space"
    fi
  done <<< "$(echo -e "$text")"
}

title(){
  clear
  msg -bar
  if [[ -z $2 ]]; then
    print_center -azu "$1"
  else
    print_center "$1" "$2"
  fi
  msg -bar
}

enter(){
  msg -bar
  local text="►► Tekan enter untuk melanjutkan ◄◄"
  if [[ -z $1 ]]; then
    print_center -ama "$text"
  else
    print_center "$1" "$text"
  fi
  read -r
}

back(){
  msg -bar
  echo -ne "$(msg -verd " [0]") $(msg -verm2 ">") " && msg -bra "\033[1;41mKEMBALI"
  msg -bar
}

menu_func(){
  local options=${#@}
  for((num=1; num<=$options; num++)); do
    echo -ne "$(msg -verd " [$num]") $(msg -verm2 ">") "
    local arr=(${!num})
    case ${arr[0]} in
      "-vd") echo -e "\033[1;33m[!]\033[1;32m ${arr[@]:1}";;
      "-vm") echo -e "\033[1;33m[!]\033[1;31m ${arr[@]:1}";;
      *)     echo -e "\033[1;37m${arr[@]}";;
    esac
  done
}

selection_fun(){
  local selection="null"
  local opcion col
  if [[ -z $2 ]]; then
    opcion=$1; col="-nazu"
  else
    opcion=$2; col=$1
  fi
  local range=()
  for((i=0; i<=$opcion; i++)); do range[$i]="$i "; done
  while [[ ! $(echo "${range[*]}" | grep -w "$selection") ]]; do
    msg "$col" " Pilih Opsi: " >&2
    read -r selection
    tput cuu1 >&2 && tput dl1 >&2
  done
  echo "$selection"
}

in_opcion_down(){
  local dat="$1"
  local length=${#dat}
  local cal=$(( 22 - length / 2 ))
  local line=''
  for (( i = 0; i < cal; i++ )); do line+='╼'; done
  echo -e " $(msg -verm3 "╭${line}╼[")$(msg -azu "$dat")$(msg -verm3 "]")"
  echo -ne " $(msg -verm3 "╰╼")\033[37;1m> " && read -r opcion
}

del(){
  for (( i = 0; i < $1; i++ )); do
    tput cuu1 && tput dl1
  done
}

numero='^[0-9]+$'

# ================================================================
# CEK ROOT
# ================================================================

cek_root(){
  if [[ $EUID -ne 0 ]]; then
    clear
    msg -bar
    print_center -verm2 "Script ini membutuhkan akses root"
    print_center -ama   "Jalankan: sudo bash $0"
    msg -bar
    exit 1
  fi
}

# ================================================================
# CEK SISTEM OPERASI - ALL DEBIAN & UBUNTU
# ================================================================

cek_sistem(){
  source /etc/os-release 2>/dev/null
  VER=$(echo "$VERSION_ID" | awk -F '.' '{print $1}')
  gagal(){
    clear
    msg -bar
    print_center -verm2 "Sistem operasi tidak didukung!"
    print_center -ama   "Gunakan Debian 9+ atau Ubuntu 18.04+"
    msg -bar
    rm -rf "$udp_file" 2>/dev/null
    exit 1
  }
  case "$ID" in
    ubuntu) [[ $VER -lt 18 ]] && gagal ;;
    debian) [[ $VER -lt 9  ]] && gagal ;;
    *)      gagal ;;
  esac
}

# ================================================================
# INSTALL DEPENDENSI (Support semua region / mirror)
# ================================================================

install_deps(){
  source /etc/os-release 2>/dev/null
  export DEBIAN_FRONTEND=noninteractive
  export LC_ALL=C
  export LANG=C

  msg -ama "   Memperbarui daftar paket..."
  # Nonaktifkan interactive prompt apt
  echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections 2>/dev/null

  apt-get update -y -qq 2>/dev/null || apt-get update -y 2>/dev/null

  msg -ama "   Menginstal dependensi..."
  for pkg in wget curl openssl iproute2 procps cron; do
    apt-get install -y -qq "$pkg" 2>/dev/null || \
    apt-get install -y "$pkg" 2>/dev/null
  done

  # Nonaktifkan UFW & hapus netfilter (agar port UDP tidak diblokir)
  ufw disable 2>/dev/null
  systemctl stop  ufw 2>/dev/null
  systemctl disable ufw 2>/dev/null
  apt-get remove -y --purge netfilter-persistent iptables-persistent 2>/dev/null
  systemctl daemon-reload 2>/dev/null
  msg -verd "   Dependensi selesai dipasang"
}

# ================================================================
# TIMER REBOOT
# ================================================================

time_reboot(){
  print_center -ama "VPS AKAN DIRESTART DALAM $1 DETIK"
  local TIMEOUT="$1"
  while [ $TIMEOUT -gt 0 ]; do
    printf "\r                    -%s-     " "$TIMEOUT"
    sleep 1
    : $((TIMEOUT--))
  done
  echo ""
  reboot
}

# ================================================================
# AMBIL IP PUBLIK (Multi-fallback, support semua region)
# ================================================================

get_ip_publik(){
  ip_publik=""
  local sources=(
    "http://ip1.dynupdate.no-ip.com/"
    "https://api.ipify.org"
    "https://ifconfig.me"
    "https://icanhazip.com"
    "https://ipecho.net/plain"
    "https://checkip.amazonaws.com"
    "https://api4.my-ip.io/ip"
  )
  for src in "${sources[@]}"; do
    ip_publik=$(wget -T 5 -t 1 -4qO- "$src" 2>/dev/null | tr -d '[:space:]' \
      || curl -m 5 -4Ls "$src" 2>/dev/null | tr -d '[:space:]')
    ip_publik=$(grep -m 1 -oE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' <<< "$ip_publik")
    [[ -n "$ip_publik" ]] && break
  done
  [[ -z "$ip_publik" ]] && ip_publik="IP-TIDAK-DIKETAHUI"
}

# ================================================================
# DOWNLOAD BINARY UDPSERVER
# ================================================================

download_udpServer(){
  msg -nama "        Mengunduh binary UDPserver ....."
  local ok=0
  wget -q --tries=3 --timeout=30 -O /usr/bin/udpServer "$BIN_URL" 2>/dev/null && ok=1
  if [[ $ok -eq 0 ]]; then
    curl -fsSL --connect-timeout 30 --retry 3 -o /usr/bin/udpServer "$BIN_URL" 2>/dev/null && ok=1
  fi
  if [[ $ok -eq 1 && -s /usr/bin/udpServer ]]; then
    chmod +x /usr/bin/udpServer
    msg -verd 'OK'
  else
    msg -verm2 'GAGAL'
    rm -f /usr/bin/udpServer
  fi
}

# ================================================================
# PILIH PORT YANG DIKECUALIKAN
# ================================================================

exclude(){
  title "Kecualikan Port UDP"
  print_center -ama "UDPserver mencakup semua rentang port."
  print_center -ama "Anda dapat mengecualikan port tertentu"
  msg -bar3
  print_center -ama "Contoh port yang dikecualikan:"
  print_center -ama "slowdns  (UDP 53 5300)"
  print_center -ama "wireguard (UDP 51820)"
  print_center -ama "openvpn  (UDP 1194)"
  msg -bar
  print_center -verd "Masukkan port dipisah spasi"
  print_center -verd "Contoh: 53 5300 51820 1194"
  msg -bar3
  in_opcion_down "Ketik port atau Enter untuk lewati"
  del 2
  local tmport=($opcion)
  for (( i = 0; i < ${#tmport[@]}; i++ )); do
    local num=$((${tmport[$i]}))
    if [[ $num -gt 0 && $num -le 65535 ]]; then
      echo "$(msg -ama " Port dikecualikan >") $(msg -azu "$num") $(msg -verd "OK")"
      Port+=" $num"
    else
      msg -verm2 " Bukan port valid > ${tmport[$i]}"
    fi
  done
  if [[ -z $Port ]]; then
    unset Port
    print_center -ama "Tidak ada port yang dikecualikan"
  else
    Port=" -exclude=$(echo "$Port" | sed "s/ /,/g" | sed 's/,//')"
  fi
  msg -bar3
}

# ================================================================
# BUAT SYSTEMD SERVICE
# ================================================================

buat_service(){
  source /etc/os-release 2>/dev/null
  local ip_nat
  ip_nat=$(ip -4 addr 2>/dev/null | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' \
    | cut -d '/' -f1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | sed -n 1p)
  local interfas
  interfas=$(ip -4 addr 2>/dev/null | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' \
    | grep "$ip_nat" | awk '{print $NF}')
  get_ip_publik

cat > "$SERVICE" <<EOF
[Unit]
Description=UDPserver Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=/usr/bin/udpServer -ip=${ip_publik} -net=${interfas}${Port} -mode=system
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

  msg -nama "        Menjalankan service UDPserver ....."
  systemctl daemon-reload 2>/dev/null
  systemctl start UDPserver 2>/dev/null
  sleep 2
  if [[ $(systemctl is-active UDPserver 2>/dev/null) = 'active' ]]; then
    systemctl enable UDPserver 2>/dev/null
    msg -verd 'OK'
  else
    msg -verm2 'GAGAL'
    msg -ama "   Cek log: journalctl -u UDPserver -n 20"
  fi
}

# ================================================================
# INSTALL UDPSERVER
# ================================================================

install_UDP(){
  title "INSTALASI UDPSERVER"
  exclude
  install_deps
  download_udpServer
  if [[ -x /usr/bin/udpServer ]]; then
    buat_service
    msg -bar3
    if [[ $(systemctl is-active UDPserver 2>/dev/null) = 'active' ]]; then
      print_center -verd "Instalasi berhasil!"
    else
      print_center -verm2 "Gagal menjalankan service"
      print_center -ama   "Cek: journalctl -u UDPserver -n 30"
    fi
  else
    echo
    print_center -verm2 "Gagal mengunduh binary UDPserver"
    print_center -ama   "Periksa koneksi internet VPS"
  fi
  enter
}

# ================================================================
# UNINSTALL UDPSERVER
# ================================================================

uninstall_UDP(){
  title "HAPUS UDPSERVER"
  read -rp " $(msg -ama "Yakin ingin menghapus UDPserver? [Y/T]: ")" KONFIRM
  [[ ! $KONFIRM =~ ^[Yy]$ ]] && return
  systemctl stop    UDPserver 2>/dev/null
  systemctl disable UDPserver 2>/dev/null
  rm -f "$SERVICE"
  rm -f /usr/bin/udpServer
  systemctl daemon-reload 2>/dev/null
  del 1
  print_center -ama "UDPserver berhasil dihapus!"
  enter
}

# ================================================================
# START / STOP SERVICE
# ================================================================

toggle_service(){
  if [[ $(systemctl is-active UDPserver 2>/dev/null) = 'active' ]]; then
    systemctl stop    UDPserver 2>/dev/null
    systemctl disable UDPserver 2>/dev/null
    print_center -ama "UDPserver dihentikan!"
  else
    systemctl start UDPserver 2>/dev/null
    sleep 2
    if [[ $(systemctl is-active UDPserver 2>/dev/null) = 'active' ]]; then
      systemctl enable UDPserver 2>/dev/null
      print_center -verd "UDPserver berhasil dijalankan!"
    else
      print_center -verm2 "Gagal menjalankan UDPserver!"
    fi
  fi
  enter
}

# ================================================================
# HAPUS SCRIPT PENUH
# ================================================================

hapus_script(){
  title "HAPUS SCRIPT UDPSERVER"
  read -rp " $(msg -ama "Yakin ingin menghapus SEMUA script? [Y/T]: ")" KONFIRM
  [[ ! $KONFIRM =~ ^[Yy]$ ]] && return
  systemctl disable UDPserver 2>/dev/null
  systemctl stop    UDPserver 2>/dev/null
  rm -f "$SERVICE"
  rm -f /usr/bin/udpServer
  rm -f /usr/bin/udp
  rm -f /usr/bin/udpc
  rm -rf "$udp_file"
  systemctl daemon-reload 2>/dev/null
  # Hapus cron limitador
  crontab -l 2>/dev/null | grep -v 'limitador.sh' | crontab - 2>/dev/null
  clear
  msg -bar
  print_center -verd "Script berhasil dihapus sepenuhnya!"
  print_center -ama  "Ketik 'exit' untuk keluar dari sesi ini."
  msg -bar
  exit 0
}

# ================================================================
# HELPER USER
# ================================================================

tampil_pengguna(){
  cat /etc/passwd | grep '/home' | grep '/bin/false' \
    | grep -v 'syslog\|hwid\|token\|::/' | awk -F ':' '{print $1}'
}

tabel_pengguna(){
  local cat_users
  cat_users=$(cat /etc/passwd | grep '/home' | grep '/bin/false' \
    | grep -v 'syslog\|hwid\|token\|::/')
  if [[ -z "$(echo "$cat_users" | head -1)" ]]; then
    print_center -verm2 "BELUM ADA PENGGUNA SSH TERDAFTAR"
    return 1
  fi
  local header
  header=$(printf '%-13s%-14s%-10s%-5s%-7s%s' \
    "Pengguna" "Password" "Tanggal" "Hari" "Limit" "Status")
  msg -azu "  $header"
  msg -bar
  local i=1
  while read -r baris; do
    local u pass limit fecha mes_dia ano stat exp EXPTIME
    u=$(echo "$baris" | awk -F ':' '{print $1}')
    fecha=$(chage -l "$u" 2>/dev/null | sed -n '4p' | awk -F ': ' '{print $2}')
    mes_dia=$(echo "$fecha" | awk -F ',' '{print $1}' | sed 's/ //g')
    ano=$(echo "$fecha" | awk -F ', ' '{printf $2}' | cut -c 3-)
    local us
    us=$(printf '%-12s' "$u")
    pass=$(echo "$baris" | awk -F ':' '{print $5}' | cut -d ',' -f2)
    [[ "${#pass}" -gt '12' || -z "$pass" ]] && pass="Tidak diketahui"
    pass="$(printf '%-12s' "$pass")"
    if [[ $(passwd --status "$u" 2>/dev/null | cut -d ' ' -f2) = "P" ]]; then
      stat="$(msg -verd "AKT")"
    else
      stat="$(msg -verm2 "BLK")"
    fi
    limit=$(echo "$baris" | awk -F ':' '{print $5}' | cut -d ',' -f1)
    [[ "${#limit}" = "1" ]] && limit=$(printf '%2s%-4s' "$limit") || limit=$(printf '%-6s' "$limit")
    echo -ne "$(msg -verd "$i")$(msg -verm2 "-")$(msg -azu "${us}") $(msg -azu "${pass}")"
    if [[ $(echo "$fecha" | awk '{print $2}') = "" ]]; then
      exp="$(printf '%8s%-2s' '[X]')"
      exp+="$(printf '%-6s' '[X]')"
      echo " $(msg -verm2 "$fecha")$(msg -verd "$exp")$(echo -e "$stat")"
    else
      local ts_exp ts_now
      ts_exp=$(date '+%s' -d "${fecha}" 2>/dev/null || echo 0)
      ts_now=$(date +%s)
      if [[ $ts_now -gt $ts_exp ]]; then
        exp="$(printf '%-5s' "Exp")"
        echo " $(msg -verm2 "$mes_dia/$ano")  $(msg -verm2 "$exp")$(msg -ama "$limit")$(echo -e "$stat")"
      else
        EXPTIME=$(( (ts_exp - ts_now) / 86400 ))
        [[ "${#EXPTIME}" = "1" ]] \
          && exp="$(printf '%2s%-3s' "$EXPTIME")" \
          || exp="$(printf '%-5s' "$EXPTIME")"
        echo " $(msg -verm2 "$mes_dia/$ano")  $(msg -verd "$exp")$(msg -ama "$limit")$(echo -e "$stat")"
      fi
    fi
    let i++
  done <<< "$cat_users"
}

# ================================================================
# TAMBAH PENGGUNA
# ================================================================

tambah_pengguna_sys(){
  local nama="$1" sandi="$2" hari="$3" limit="$4"
  local valid
  valid=$(date '+%Y-%m-%d' -d " +$hari days")
  local osl_v
  osl_v=$(openssl version 2>/dev/null | awk '{print $2}')
  local hash
  if [[ "${osl_v:0:1}" = '3' || "${osl_v:0:5}" = '1.1.1' ]]; then
    hash=$(openssl passwd -6 "$sandi")
  else
    hash=$(openssl passwd -1 "$sandi")
  fi
  useradd -M -s /bin/false -e "${valid}" \
    -K PASS_MAX_DAYS="$hari" \
    -p "${hash}" \
    -c "${limit},${sandi}" "$nama" 2>/dev/null
  msj=$?
}

buat_pengguna(){
  clear
  local daftar_aktif=('' $(tampil_pengguna))
  msg -bar
  print_center -ama "BUAT PENGGUNA"
  msg -bar
  tabel_pengguna
  back

  local nama sandi hari limit
  while true; do
    msg -ne " Nama Pengguna: "
    read -r nama
    nama="$(echo "$nama" | sed 's/[^a-zA-Z0-9_-]//g')"
    if [[ -z "$nama" ]]; then
      del 1; msg -verm "Nama tidak boleh kosong"; sleep 1; del 1; continue
    elif [[ "$nama" = "0" ]]; then return; fi
    if [[ "${#nama}" -lt "3" ]]; then
      del 1; msg -verm "Minimal 3 karakter"; sleep 1; del 1; continue
    elif [[ "${#nama}" -gt "16" ]]; then
      del 1; msg -verm "Maksimal 16 karakter"; sleep 1; del 1; continue
    elif [[ "$(echo "${daftar_aktif[@]}" | grep -w "$nama")" ]]; then
      del 1; msg -verm "Pengguna sudah ada"; sleep 1; del 1; continue
    fi
    break
  done

  while true; do
    msg -ne " Password Pengguna"
    read -rp ": " sandi
    if [[ -z "$sandi" ]]; then
      del 1; msg -verm "Password tidak boleh kosong"; sleep 1; del 1; continue
    elif [[ "${#sandi}" -lt "4" ]]; then
      del 1; msg -verm "Minimal 4 karakter"; sleep 1; del 1; continue
    elif [[ "${#sandi}" -gt "20" ]]; then
      del 1; msg -verm "Maksimal 20 karakter"; sleep 1; del 1; continue
    fi
    break
  done

  while true; do
    msg -ne " Masa Aktif (Hari)"
    read -rp ": " hari
    if [[ -z "$hari" ]]; then
      del 1; continue
    elif [[ "$hari" != +([0-9]) ]]; then
      del 1; msg -verm "Hanya angka"; sleep 1; del 1; continue
    elif [[ "$hari" -lt 1 || "$hari" -gt 360 ]]; then
      del 1; msg -verm "Rentang 1-360 hari"; sleep 1; del 1; continue
    fi
    break
  done

  while true; do
    msg -ne " Batas Koneksi"
    read -rp ": " limit
    if [[ -z "$limit" ]]; then
      del 1; continue
    elif [[ "$limit" != +([0-9]) ]]; then
      del 1; msg -verm "Hanya angka"; sleep 1; del 1; continue
    elif [[ "$limit" -lt 1 || "$limit" -gt 999 ]]; then
      del 1; msg -verm "Rentang 1-999"; sleep 1; del 1; continue
    fi
    break
  done

  tambah_pengguna_sys "$nama" "$sandi" "$hari" "$limit"
  clear
  msg -bar
  if [[ $msj -eq 0 ]]; then
    get_ip_publik
    print_center -verd "Pengguna Berhasil Dibuat"
  else
    print_center -verm2 "Gagal Membuat Pengguna"
    enter; return 1
  fi
  msg -bar
  msg -ne " IP Server       : " && msg -ama "  $ip_publik"
  msg -ne " Pengguna        : " && msg -ama "  $nama"
  msg -ne " Password        : " && msg -ama "  $sandi"
  msg -ne " Masa Aktif      : " && msg -ama "  $hari hari"
  msg -ne " Batas Koneksi   : " && msg -ama "  $limit"
  msg -ne " Tanggal Expired : " && msg -ama "  $(date '+%d/%m/%Y' -d " +$hari days")"
  enter
}

# ================================================================
# HAPUS PENGGUNA
# ================================================================

hapus_pengguna_sys(){
  pkill -u "$1" 2>/dev/null
  sleep 1
  userdel --force "$1" 2>/dev/null
  msj=$?
}

hapus_pengguna(){
  clear
  local daftar_aktif=('' $(tampil_pengguna))
  msg -bar
  print_center -ama "HAPUS PENGGUNA"
  msg -bar
  tabel_pengguna
  back

  print_center -ama "Ketik atau Pilih Nomor Pengguna"
  msg -bar
  local pilihan
  unset pilihan
  while [[ -z "$pilihan" ]]; do
    msg -nazu " Pilih: " && read -r pilihan
    tput cuu1 && tput dl1
  done
  [[ "$pilihan" = "0" ]] && return
  local target
  if [[ ! $(echo "$pilihan" | grep -E '[^0-9]') ]]; then
    target="${daftar_aktif[$pilihan]}"
  else
    target="$pilihan"
  fi
  [[ -z "$target" ]] && { msg -verm "Error: Pengguna tidak valid"; msg -bar; return 1; }
  [[ ! $(echo "${daftar_aktif[@]}" | grep -w "$target") ]] && \
    { msg -verm "Error: Pengguna tidak ditemukan"; msg -bar; return 1; }

  hapus_pengguna_sys "$target"
  if [[ $msj -eq 0 ]]; then
    print_center -verd "[$target] Berhasil dihapus"
  else
    print_center -verm "[$target] Gagal dihapus"
  fi
  enter
}

# ================================================================
# PERPANJANG PENGGUNA
# ================================================================

perpanjang_pengguna_sys(){
  local valid
  valid=$(date '+%Y-%m-%d' -d " +$2 days")
  if chage -E "$valid" "$1" 2>/dev/null; then
    print_center -ama "Pengguna Berhasil Diperpanjang"
  else
    print_center -verm "Gagal memperpanjang pengguna"
  fi
}

perpanjang_pengguna(){
  clear
  local daftar_aktif=('' $(tampil_pengguna))
  msg -bar
  print_center -ama "PERPANJANG PENGGUNA"
  msg -bar
  tabel_pengguna
  back

  print_center -ama "Ketik atau Pilih Nomor Pengguna"
  msg -bar
  local pilihan target
  unset pilihan
  while [[ -z "$pilihan" ]]; do
    msg -nazu " Pilih: " && read -r pilihan
    del 1
  done
  [[ "$pilihan" = "0" ]] && return
  if [[ ! $(echo "$pilihan" | grep -E '[^0-9]') ]]; then
    target="${daftar_aktif[$pilihan]}"
  else
    target="$pilihan"
  fi
  [[ -z "$target" ]] && { msg -verm "Error: Pengguna tidak valid"; msg -bar; sleep 3; return 1; }
  [[ ! $(echo "${daftar_aktif[@]}" | grep -w "$target") ]] && \
    { msg -verm "Error: Pengguna tidak ditemukan"; msg -bar; sleep 3; return 1; }

  local hari
  while true; do
    msg -ne " Masa Aktif Baru untuk $target"
    read -rp ": " hari
    if [[ -z "$hari" ]]; then
      del 1; continue
    elif [[ "$hari" != +([0-9]) ]]; then
      del 1; msg -verm "Hanya angka"; sleep 1; del 1; continue
    elif [[ "$hari" -gt 360 ]]; then
      del 1; msg -verm "Maksimal 360 hari"; sleep 1; del 1; continue
    fi
    break
  done
  msg -bar
  perpanjang_pengguna_sys "$target" "$hari"
  msg -bar
  sleep 3
}

# ================================================================
# BLOKIR / BUKA BLOKIR PENGGUNA
# ================================================================

blokir_pengguna(){
  clear
  local daftar_aktif=('' $(tampil_pengguna))
  msg -bar
  print_center -ama "BLOKIR / BUKA BLOKIR PENGGUNA"
  msg -bar
  tabel_pengguna
  back

  print_center -ama "Ketik atau Pilih Nomor Pengguna"
  msg -bar
  local pilihan target
  unset pilihan
  while [[ "$pilihan" = "" ]]; do
    echo -ne "\033[1;37m Pilih: " && read -r pilihan
    del 1
  done
  [[ "$pilihan" = "0" ]] && return
  if [[ ! $(echo "$pilihan" | grep -E '[^0-9]') ]]; then
    target="${daftar_aktif[$pilihan]}"
  else
    target="$pilihan"
  fi
  [[ -z "$target" ]] && { msg -verm "Error: Pengguna tidak valid"; msg -bar; return 1; }
  [[ ! $(echo "${daftar_aktif[@]}" | grep -w "$target") ]] && \
    { msg -verm "Error: Pengguna tidak ditemukan"; msg -bar; return 1; }

  msg -nama "   Pengguna: $target >>>> "
  if [[ $(passwd --status "$target" 2>/dev/null | cut -d ' ' -f2) = "P" ]]; then
    pkill -u "$target" 2>/dev/null
    usermod -L "$target" 2>/dev/null
    sleep 2
    msg -verm2 "DIBLOKIR"
  else
    usermod -U "$target" 2>/dev/null
    sleep 2
    msg -verd "DIBUKA"
  fi
  msg -bar
  sleep 3
}

# ================================================================
# DETAIL PENGGUNA
# ================================================================

detail_pengguna(){
  clear
  local daftar_aktif=('' $(tampil_pengguna))
  if [[ -z "${daftar_aktif[*]}" ]]; then
    msg -bar
    print_center -verm2 "Belum ada pengguna terdaftar"
    msg -bar
    sleep 3; return
  fi
  msg -bar
  print_center -ama "DETAIL PENGGUNA"
  msg -bar
  tabel_pengguna
  msg -bar
  enter
}

# ================================================================
# LIMITADOR (Pembatas Koneksi)
# ================================================================

limitador(){

  multi_login(){
    clear
    msg -bar
    if crontab -l 2>/dev/null | grep -q "limitador.sh$"; then
      crontab -l 2>/dev/null | grep -v "limitador.sh$" | crontab - 2>/dev/null
      print_center -verd "Pembatas dihentikan"
      enter; return
    fi
    print_center -ama "KONFIGURASI PEMBATAS MULTI-LOGIN"
    msg -bar
    print_center -ama "Blokir pengguna yang melebihi"
    print_center -ama "batas maksimal koneksi"
    msg -bar
    local menit
    unset menit
    while [[ -z "$menit" ]]; do
      msg -nama " Jalankan pembatas setiap (menit): "
      read -r menit
      if [[ ! $menit =~ $numero ]]; then
        del 1; print_center -verm2 "Hanya angka"; sleep 2; del 1; unset menit; continue
      elif [[ $menit -le 0 ]]; then
        del 1; print_center -verm2 "Minimal 1 menit"; sleep 2; del 1; unset menit; continue
      fi
      del 1
      echo -e "$(msg -nama " Jalankan setiap:") $(msg -verd "$menit menit")"
      echo "$menit" > "${udp_file}/limit"
    done
    msg -bar
    print_center -ama "Pengguna yang diblokir pembatas\nakan dibuka otomatis\n(masukkan 0 untuk buka manual)"
    msg -bar
    local buka
    unset buka
    while [[ -z "$buka" ]]; do
      msg -nama " Buka blokir setiap (menit, 0=manual): "
      read -r buka
      if [[ ! $buka =~ $numero ]]; then
        tput cuu1 && tput dl1
        print_center -verm2 "Hanya angka"; sleep 2; tput cuu1 && tput dl1
        unset buka; continue
      fi
      tput cuu1 && tput dl1
      [[ $buka -le 0 ]] \
        && echo -e "$(msg -nama " Buka blokir:") $(msg -verd "Manual")" \
        || echo -e "$(msg -nama " Buka blokir setiap:") $(msg -verd "$buka menit")"
      echo "$buka" > "${udp_file}/unlimit"
    done
    local mnt
    mnt=$(cat "${udp_file}/limit")
    ( crontab -l 2>/dev/null | grep -v "limitador.sh$"
      echo "*/$mnt * * * * /bin/bash ${udp_file}/limitador.sh"
    ) | crontab - 2>/dev/null
    nohup /bin/bash "${udp_file}/limitador.sh" &>/dev/null &
    msg -bar
    print_center -verd "Pembatas aktif dan berjalan"
    enter
  }

  expired_login(){
    clear
    msg -bar
    local l_cron
    l_cron=$(crontab -l 2>/dev/null | grep -w 'limitador.sh' | grep -w 'ssh')
    if [[ -z "$l_cron" ]]; then
      ( crontab -l 2>/dev/null | grep -v 'limitador.sh --ssh'
        echo "0 1 * * * /bin/bash ${udp_file}/limitador.sh --ssh"
      ) | crontab - 2>/dev/null
      print_center -verd "Pembatas expired dijadwalkan\nBerjalan setiap hari jam 1 pagi\nSesuai waktu server"
    else
      crontab -l 2>/dev/null | grep -v 'limitador.sh --ssh' | crontab - 2>/dev/null
      print_center -verm2 "Pembatas expired dihentikan"
    fi
    enter; return
  }

  log_limitador(){
    clear; msg -bar
    print_center -ama "LOG PEMBATAS KONEKSI"
    msg -bar
    [[ ! -e "${udp_file}/limit.log" ]] && touch "${udp_file}/limit.log"
    if [[ -z $(cat "${udp_file}/limit.log") ]]; then
      print_center -ama "Belum ada log pembatas"
      msg -bar; sleep 2; return
    fi
    msg -teal "$(cat "${udp_file}/limit.log")"
    msg -bar
    print_center -ama "►► Enter untuk lanjut atau 0 untuk hapus log ◄◄"
    read -r pilihan
    [[ "$pilihan" = "0" ]] && echo "" > "${udp_file}/limit.log"
  }

  local lim_e
  [[ $(crontab -l 2>/dev/null | grep -w 'limitador.sh' | grep -w 'ssh') ]] \
    && lim_e=$(msg -verd "[ON]") || lim_e=$(msg -verm2 "[OFF]")

  clear; msg -bar
  print_center -ama "PEMBATAS KONEKSI"
  msg -bar
  menu_func "PEMBATAS MULTI-LOGIN" "PEMBATAS EXPIRED $lim_e" "LOG PEMBATAS"
  back
  msg -ne " Opsi: "
  read -r pilihan
  case $pilihan in
    1) multi_login   ;;
    2) expired_login ;;
    3) log_limitador ;;
    0) return        ;;
  esac
}

# ================================================================
# MANAJEMEN PORT PENGECUALIAN
# ================================================================

tambah_exclude(){
  title "Tambah Port Pengecualian"
  print_center -ama "UDPserver mencakup semua rentang port."
  print_center -ama "Anda dapat mengecualikan port tertentu"
  msg -bar3
  print_center -ama "Contoh port yang dikecualikan:"
  print_center -ama "slowdns  (UDP 53 5300)"
  print_center -ama "wireguard (UDP 51820)"
  print_center -ama "openvpn  (UDP 1194)"
  msg -bar
  print_center -verd "Masukkan port dipisah spasi"
  print_center -verd "Contoh: 53 5300 51820 1194"
  in_opcion_down "Ketik port atau Enter untuk lewati"
  del 4
  local tmport=($opcion)
  unset Port
  for (( i = 0; i < ${#tmport[@]}; i++ )); do
    local num=$((${tmport[$i]}))
    if [[ $num -gt 0 && $num -le 65535 ]]; then
      echo "$(msg -ama " Port dikecualikan >") $(msg -azu "$num") $(msg -verd "OK")"
      Port+=" $num"
    else
      msg -verm2 " Bukan port valid > ${tmport[$i]}"
    fi
  done
  if [[ -z $Port ]]; then
    unset Port
    print_center -ama "Tidak ada port yang ditambahkan"
  else
    local cur_excl
    cur_excl=$(grep 'exclude' "$SERVICE" 2>/dev/null)
    local sedang_aktif=0
    systemctl is-active UDPserver &>/dev/null && sedang_aktif=1
    [[ $sedang_aktif -eq 1 ]] && { systemctl stop UDPserver 2>/dev/null; systemctl disable UDPserver 2>/dev/null; }
    if [[ -z "$cur_excl" ]]; then
      Port=" -exclude=$(echo "$Port" | sed "s/ /,/g" | sed 's/,//')"
      sed -i "s/ -mode/$Port -mode/" "$SERVICE"
    else
      local excl_port
      excl_port=$(echo "$cur_excl" | awk '{print $4}' | cut -d '=' -f2)
      Port="-exclude=$excl_port$(echo "$Port" | sed "s/ /,/g")"
      sed -i "s/-exclude=$excl_port/$Port/" "$SERVICE"
    fi
    systemctl daemon-reload 2>/dev/null
    [[ $sedang_aktif -eq 1 ]] && { systemctl start UDPserver 2>/dev/null; systemctl enable UDPserver 2>/dev/null; }
  fi
  enter
}

hapus_exclude(){
  title "HAPUS PORT PENGECUALIAN"
  local excl_line
  excl_line=$(grep 'exclude' "$SERVICE" 2>/dev/null | awk '{print $4}')
  if [[ -z "$excl_line" ]]; then
    print_center -ama "Tidak ada port yang dikecualikan"
    enter; return
  fi
  local port_str
  port_str=$(echo "$excl_line" | cut -d '=' -f2 | sed 's/,/ /g')
  local ports=($port_str)
  local a
  for (( i = 0; i < ${#ports[@]}; i++ )); do
    a=$(($i+1))
    echo "             $(msg -verd "[$a]") $(msg -verm2 '>') $(msg -azu "${ports[$i]}")"
  done
  if [[ ! ${#ports[@]} = 1 ]]; then
    let a++
    msg -bar
    echo "             $(msg -verd "[0]") $(msg -verm2 ">") $(msg -bra "\033[1;41mKEMBALI")  $(msg -verd "[$a]") $(msg -verm2 "> HAPUS SEMUA")"
    msg -bar
  else
    msg -bar
    echo "             $(msg -verd "[0]") $(msg -verm2 ">") $(msg -bra "\033[1;41mKEMBALI")"
    msg -bar
  fi
  local pilihan
  pilihan=$(selection_fun $a)
  [[ $pilihan = 0 ]] && return
  local sedang_aktif=0
  systemctl is-active UDPserver &>/dev/null && sedang_aktif=1
  [[ $sedang_aktif -eq 1 ]] && { systemctl stop UDPserver 2>/dev/null; systemctl disable UDPserver 2>/dev/null; }
  if [[ $pilihan = $a ]]; then
    sed -i "s/ -exclude=[^ ]*//" "$SERVICE"
    print_center -ama "Semua port pengecualian dihapus"
  else
    let pilihan--
    local NewPort=""
    for (( i = 0; i < ${#ports[@]}; i++ )); do
      [[ $i = $pilihan ]] && continue
      echo "$(msg -ama " Port dikecualikan >") $(msg -azu "${ports[$i]}") $(msg -verd "OK")"
      NewPort+=" ${ports[$i]}"
    done
    NewPort=$(echo "$NewPort" | sed 's/ /,/g' | sed 's/^,//')
    if [[ -z "$NewPort" ]]; then
      sed -i "s/ -exclude=[^ ]*//" "$SERVICE"
    else
      sed -i "s/-exclude=[^ ]*/-exclude=$NewPort/" "$SERVICE"
    fi
  fi
  systemctl daemon-reload 2>/dev/null
  [[ $sedang_aktif -eq 1 ]] && { systemctl start UDPserver 2>/dev/null; systemctl enable UDPserver 2>/dev/null; }
  enter
}

# ================================================================
# BUAT FILE LIMITADOR.SH
# ================================================================

buat_limitador(){
cat > "${udp_file}/limitador.sh" <<'LIMITADOR'
#!/bin/bash
# Pembatas Koneksi UDPserver
udp_file='/etc/UDPserver'
LOG="${udp_file}/limit.log"
[[ ! -f "$LOG" ]] && touch "$LOG"

# Mode --ssh : blokir pengguna expired
if [[ "$1" == "--ssh" ]]; then
  while IFS=: read -r u x uid gid info home shell; do
    [[ "$shell" != "/bin/false" ]] && continue
    [[ "$home"  != /home/*      ]] && continue
    [[ "$u" =~ syslog|hwid|token ]] && continue
    exp=$(chage -l "$u" 2>/dev/null | sed -n '4p' | awk -F ': ' '{print $2}')
    [[ -z "$exp" || "$exp" == "never" ]] && continue
    ts_exp=$(date '+%s' -d "$exp" 2>/dev/null) || continue
    if [[ $(date +%s) -gt $ts_exp ]]; then
      usermod -L "$u" 2>/dev/null
      echo "$(date '+%F %T') [EXPIRED-BLOKIR] $u" >> "$LOG"
    fi
  done < /etc/passwd
  exit 0
fi

# Mode normal : batasi multi-login
[[ -f "${udp_file}/limit"   ]] && interval=$(cat "${udp_file}/limit")  || interval=1
[[ -f "${udp_file}/unlimit" ]] && buka=$(cat "${udp_file}/unlimit")    || buka=0

while IFS=: read -r u x uid gid info home shell; do
  [[ "$shell" != "/bin/false" ]] && continue
  [[ "$home"  != /home/*      ]] && continue
  [[ "$u" =~ syslog|hwid|token ]] && continue
  lim=$(echo "$info" | cut -d',' -f1)
  [[ ! "$lim" =~ ^[0-9]+$ ]] && continue
  koneksi=$(ps -u "$u" 2>/dev/null | grep -vc 'PID')
  if [[ $koneksi -gt $lim ]]; then
    pkill -u "$u" 2>/dev/null
    usermod -L "$u" 2>/dev/null
    echo "$(date '+%F %T') [LIMIT-BLOKIR] $u (koneksi=$koneksi / batas=$lim)" >> "$LOG"
    if [[ $buka -gt 0 ]]; then
      ( sleep "${buka}m"
        usermod -U "$u" 2>/dev/null
        echo "$(date '+%F %T') [BUKA-OTOMATIS] $u" >> "$LOG"
      ) &
    fi
  fi
done < /etc/passwd
LIMITADOR
  chmod +x "${udp_file}/limitador.sh"
}

# ================================================================
# SETUP PERTAMA KALI
# ================================================================

setup_awal(){
  clear
  msg -bar
  print_center -ama "SETUP AWAL UDPSERVER"
  msg -bar

  # 1. Buat direktori kerja
  mkdir -p "$udp_file"
  chmod 755 "$udp_file"

  # 2. Install dependensi dulu (wget/curl dibutuhkan untuk download script)
  print_center -ama "Memperbarui sistem & dependensi..."
  install_deps
  print_center -verd "Dependensi selesai"

  # 3. Buat script pembatas
  buat_limitador

  # 4. Salin script ini ke lokasi permanen
  #    Coba dari BASH_SOURCE[0] dulu.
  #    Jika dijalankan via pipe (bash <(wget...)), download ulang dari URL.
  local script_src="${BASH_SOURCE[0]}"
  if [[ -f "$script_src" && "$script_src" != "/dev/fd/"* && -s "$script_src" ]]; then
    cp "$script_src" "$udp_file/UDPserver.sh"
  else
    print_center -ama "Mengunduh script ke lokasi permanen..."
    local SCRIPT_URL='https://github.com/chanelog/Ogh/raw/refs/heads/main/UDPserver.sh'
    wget -q --tries=3 --timeout=30 -O "$udp_file/UDPserver.sh" "$SCRIPT_URL" 2>/dev/null \
    || curl -fsSL --connect-timeout 30 --retry 3 -o "$udp_file/UDPserver.sh" "$SCRIPT_URL" 2>/dev/null
  fi
  chmod +x "$udp_file/UDPserver.sh"

  # 5. Buat perintah global 'udp' — gunakan heredoc agar tidak ada masalah escape
  cat > /usr/bin/udp <<'UDPCMD'
#!/bin/bash
bash /etc/UDPserver/UDPserver.sh "$@"
UDPCMD
  chmod +x /usr/bin/udp

  # 6. Buat perintah global 'udpc' (huruf kecil) — alias untuk 'udp'
  cat > /usr/bin/udpc <<'UDPCCMD'
#!/bin/bash
bash /etc/UDPserver/UDPserver.sh "$@"
UDPCCMD
  chmod +x /usr/bin/udpc

  # Verifikasi
  if [[ -f "$udp_file/UDPserver.sh" && -x /usr/bin/udp && -x /usr/bin/udpc ]]; then
    print_center -verd "Setup selesai! Ketik 'udp' atau 'udpc' untuk membuka menu."
  else
    print_center -verm2 "Peringatan: Gagal membuat file permanen."
    print_center -ama   "Cek koneksi internet VPS."
  fi
  sleep 2
}

# ================================================================
# MENU UTAMA
# ================================================================

menu_utama(){
  source /etc/os-release 2>/dev/null
  get_ip_publik

  if [[ -x /usr/bin/udpServer ]]; then
    # UDPserver sudah terinstal
    local port_info
    port_info=$(grep 'exclude' "$SERVICE" 2>/dev/null)
    local port_tampil=""
    if [[ -n "$port_info" ]]; then
      port_tampil=$(echo "$port_info" | awk '{print $4}' | cut -d '=' -f2 | sed 's/,/ /g')
    fi

    local ram cpu
    ram=$(free -m 2>/dev/null | awk 'NR==2{printf "%.1f%%", $3*100/$2}')
    cpu=$(top -bn1 2>/dev/null | awk '/[Cc]pu/ {val=100-$8; printf "%.1f%%", val; exit}')

    title "MANAJER UDPSERVER"
    print_center -ama 'Binary UDPserver by chanelog'
    print_center -ama 'Klien Android: SocksIP'
    msg -bar

    [[ -n "$port_tampil" ]] && { print_center -ama "PORT DIKECUALIKAN: $port_tampil"; msg -bar; }

    echo " $(msg -verd 'IP     :') $(msg -azu "$ip_publik")"
    echo " $(msg -verd 'RAM    :') $(msg -azu "$ram")    $(msg -verd 'CPU:') $(msg -azu "$cpu")"
    echo " $(msg -verd 'Sistem :') $(msg -azu "$NAME $VERSION_ID")"
    msg -bar

    local status_svc
    if [[ $(systemctl is-active UDPserver 2>/dev/null) = 'active' ]]; then
      status_svc="\e[1m\e[32m[AKTIF]"
    else
      status_svc="\e[1m\e[31m[MATI]"
    fi

    echo " $(msg -verd "[1]")  $(msg -verm2 '>') $(msg -verm2 "HAPUS UDPSERVER")"
    echo -e " $(msg -verd "[2]")  $(msg -verm2 '>') $(msg -azu "MULAI/HENTIKAN UDPSERVER") $status_svc"
    echo " $(msg -verd "[3]")  $(msg -verm2 '>') $(msg -azu "HAPUS SCRIPT SEPENUHNYA")"
    msg -bar3
    echo " $(msg -verd "[4]")  $(msg -verm2 '>') $(msg -verd "BUAT PENGGUNA")"
    echo " $(msg -verd "[5]")  $(msg -verm2 '>') $(msg -verm2 "HAPUS PENGGUNA")"
    echo " $(msg -verd "[6]")  $(msg -verm2 '>') $(msg -ama "PERPANJANG PENGGUNA")"
    echo " $(msg -verd "[7]")  $(msg -verm2 '>') $(msg -azu "BLOKIR/BUKA BLOKIR PENGGUNA")"
    echo " $(msg -verd "[8]")  $(msg -verm2 '>') $(msg -blu "DETAIL PENGGUNA")"
    echo " $(msg -verd "[9]")  $(msg -verm2 '>') $(msg -azu "PEMBATAS KONEKSI")"
    msg -bar3
    print_center -ama "PENGECUALIAN PORT"
    msg -bar3
    echo " $(msg -verd "[10]") $(msg -verm2 '>') $(msg -verd "TAMBAH PORT PENGECUALIAN")"
    local num=10
    if [[ -n "$port_tampil" ]]; then
      echo " $(msg -verd "[11]") $(msg -verm2 '>') $(msg -verm2 "HAPUS PORT PENGECUALIAN")"
      num=11
    fi
    local a=x b=1
  else
    # UDPserver belum terinstal
    title "MANAJER UDPSERVER"
    print_center -ama 'Binary UDPserver by chanelog'
    print_center -ama 'Klien Android: SocksIP'
    msg -bar
    echo " $(msg -verd 'IP     :') $(msg -azu "$ip_publik")"
    echo " $(msg -verd 'Sistem :') $(msg -azu "$NAME $VERSION_ID")"
    msg -bar
    echo " $(msg -verd "[1]") $(msg -verm2 '>') $(msg -verd "INSTAL UDPSERVER")"
    local num=1 a=1 b=x
  fi

  back
  local pilihan
  pilihan=$(selection_fun $num)

  case $pilihan in
    $a) install_UDP       ;;
    $b) uninstall_UDP     ;;
    2)  toggle_service    ;;
    3)  hapus_script      ;;
    4)  buat_pengguna     ;;
    5)  hapus_pengguna    ;;
    6)  perpanjang_pengguna ;;
    7)  blokir_pengguna   ;;
    8)  detail_pengguna   ;;
    9)  limitador         ;;
    10) tambah_exclude    ;;
    11) hapus_exclude     ;;
    0)  return 1          ;;
  esac
}

# ================================================================
# TITIK MASUK PROGRAM
# ================================================================

cek_root
source /etc/os-release 2>/dev/null
cek_sistem

# Setup pertama kali - TANPA REBOOT, langsung masuk menu
if [[ ! -f "$udp_file/UDPserver.sh" ]]; then
  setup_awal
fi

# Pastikan limitador ada
[[ ! -f "${udp_file}/limitador.sh" ]] && buat_limitador

# Loop menu utama — langsung tampil, tidak perlu reboot atau ketik 'udp'
while true; do
  menu_utama
  [[ $? -ne 0 ]] && break
done
