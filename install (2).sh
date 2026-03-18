#!/bin/bash
# ─────────────────────────────────────────────────
#   UDP ZivPN Manager - Installer
#   github.com/USERNAME/REPO  ← ganti ini
# ─────────────────────────────────────────────────

MAIN_GO_URL="https://github.com/chanelog/Ogh/raw/refs/heads/main/main.go"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${CYAN}[*]${NC} $1"; }
ok()   { echo -e "${GREEN}[✓]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

# Root check
[ "$(id -u)" -ne 0 ] && err "Jalankan sebagai root: sudo bash install.sh"

clear
echo -e "\n${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}       UDP ZivPN Manager Installer        ${NC}"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Install dependency
log "Mengecek dependency..."
for pkg in wget curl; do
    if ! command -v $pkg &>/dev/null; then
        log "Menginstall $pkg..."
        apt-get install -y $pkg -qq || yum install -y $pkg -q
    fi
done
ok "Dependency siap"

# Install Go jika belum ada
if ! command -v go &>/dev/null; then
    log "Menginstall Golang..."
    OS_ARCH=$(uname -m)
    GO_VER="1.22.3"
    if [ "$OS_ARCH" = "x86_64" ]; then
        GO_URL="https://go.dev/dl/go${GO_VER}.linux-amd64.tar.gz"
    elif [ "$OS_ARCH" = "aarch64" ]; then
        GO_URL="https://go.dev/dl/go${GO_VER}.linux-arm64.tar.gz"
    else
        err "Arsitektur tidak didukung: $OS_ARCH"
    fi
    wget -qO /tmp/go.tar.gz "$GO_URL" || err "Gagal download Go"
    rm -rf /usr/local/go
    tar -C /usr/local -xzf /tmp/go.tar.gz
    rm -f /tmp/go.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    ok "Golang berhasil diinstall"
fi

GO_BIN=$(command -v go || echo "/usr/local/go/bin/go")
ok "Go ditemukan: $($GO_BIN version)"

# Download main.go dari GitHub
BUILD_DIR=$(mktemp -d)
log "Download source dari GitHub..."
wget -qO "$BUILD_DIR/main.go" "$MAIN_GO_URL" || err "Gagal download main.go dari GitHub"
ok "Source berhasil didownload"

# Build
cd "$BUILD_DIR"
"$GO_BIN" mod init zivpn-manager 2>/dev/null
log "Kompilasi binary..."
CGO_ENABLED=0 "$GO_BIN" build -ldflags="-s -w" -o /usr/local/bin/zivpn-manager . \
    || err "Gagal kompilasi"
chmod +x /usr/local/bin/zivpn-manager
ok "Binary berhasil dikompilasi → /usr/local/bin/zivpn-manager"

# Install ZivPN binary & config
log "Menginstall ZivPN..."
/usr/local/bin/zivpn-manager install

# Cleanup
cd /
rm -rf "$BUILD_DIR"

echo -e "\n${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}  ✓ Instalasi selesai!${NC}"
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo -e "  Jalankan manager : ${YELLOW}zivpn-manager${NC}"
echo -e "  Bantuan perintah : ${YELLOW}zivpn-manager help${NC}\n"
