package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"
)

// ─── Konstanta ───────────────────────────────────────────────────────────────

const (
	BinURL     = "https://github.com/fauzanihanipah/ziv-udp/releases/download/udp-zivpn/udp-zivpn-linux-amd64"
	ConfigURL  = "https://github.com/fauzanihanipah/ziv-udp/raw/main/config.json"
	InstallDir = "/etc/zivpn"
	BinPath    = "/usr/local/bin/zivpn"
	ConfigPath = "/etc/zivpn/config.json"
	UserDB     = "/etc/zivpn/users.json"
	BotCfgFile  = "/etc/zivpn/bot.json"
	DomainFile  = "/etc/zivpn/domain.json"
	ServiceFile = "/etc/systemd/system/zivpn.service"
	Version     = "1.0.0"
)

// ─── Struktur Data ────────────────────────────────────────────────────────────

type User struct {
	Username  string    `json:"username"`
	Password  string    `json:"password"`
	ExpDate   string    `json:"exp_date"`
	MaxLogin  int       `json:"max_login"`
	CreatedAt time.Time `json:"created_at"`
	CreatedBy string    `json:"created_by"`
	Note      string    `json:"note"`
}

type UserDB struct {
	Users []User `json:"users"`
}

type BotConfig struct {
	Token  string `json:"token"`
	ChatID string `json:"chat_id"`
}

type DomainConfig struct {
	Domain    string    `json:"domain"`
	UpdatedAt time.Time `json:"updated_at"`
}

type ZivConfig struct {
	Port     int    `json:"port"`
	DNS      string `json:"dns"`
	LogLevel string `json:"log_level"`
}

// ─── Warna Terminal ───────────────────────────────────────────────────────────

var (
	RED    = "\033[0;31m"
	GREEN  = "\033[0;32m"
	YELLOW = "\033[0;33m"
	BLUE   = "\033[0;34m"
	PURPLE = "\033[0;35m"
	CYAN   = "\033[0;36m"
	WHITE  = "\033[1;37m"
	RESET  = "\033[0m"
	BOLD   = "\033[1m"
)

// ─── Helper ───────────────────────────────────────────────────────────────────

func color(c, text string) string { return c + text + RESET }
func printLine()                  { fmt.Println(color(CYAN, strings.Repeat("─", 55))) }
func printHeader(title string) {
	printLine()
	pad := (53 - len(title)) / 2
	fmt.Println(color(CYAN, "│") + strings.Repeat(" ", pad) + color(BOLD+WHITE, title) + strings.Repeat(" ", 53-pad-len(title)) + color(CYAN, "│"))
	printLine()
}

func readInput(prompt string) string {
	fmt.Print(color(YELLOW, prompt))
	sc := bufio.NewScanner(os.Stdin)
	sc.Scan()
	return strings.TrimSpace(sc.Text())
}

func confirm(prompt string) bool {
	ans := readInput(prompt + " [y/N]: ")
	return strings.ToLower(ans) == "y"
}

func isRoot() bool { return os.Getuid() == 0 }

func checkRoot() {
	if !isRoot() {
		fmt.Println(color(RED, "✗ Script harus dijalankan sebagai root!"))
		os.Exit(1)
	}
}

func runCmd(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func runCmdOutput(name string, args ...string) (string, error) {
	out, err := exec.Command(name, args...).Output()
	return strings.TrimSpace(string(out)), err
}

// ─── Database User ────────────────────────────────────────────────────────────

func loadUsers() UserDB {
	data, err := os.ReadFile(UserDB)
	if err != nil {
		return UserDB{Users: []User{}}
	}
	var db UserDB
	json.Unmarshal(data, &db)
	return db
}

func saveUsers(db UserDB) error {
	data, err := json.MarshalIndent(db, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(UserDB, data, 0600)
}

func userExists(username string) bool {
	db := loadUsers()
	for _, u := range db.Users {
		if u.Username == username {
			return true
		}
	}
	return false
}

func getUser(username string) *User {
	db := loadUsers()
	for i, u := range db.Users {
		if u.Username == username {
			return &db.Users[i]
		}
	}
	return nil
}

func isExpired(expDate string) bool {
	t, err := time.Parse("2006-01-02", expDate)
	if err != nil {
		return false
	}
	return time.Now().After(t)
}

func daysLeft(expDate string) int {
	t, err := time.Parse("2006-01-02", expDate)
	if err != nil {
		return 0
	}
	diff := time.Until(t)
	return int(diff.Hours() / 24)
}

// ─── Download & Install ───────────────────────────────────────────────────────

func downloadFile(url, dest string) error {
	resp, err := http.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	out, err := os.Create(dest)
	if err != nil {
		return err
	}
	defer out.Close()

	_, err = io.Copy(out, resp.Body)
	return err
}

func installBin() error {
	fmt.Println(color(YELLOW, "  ↓ Mengunduh binary ZivPN..."))
	tmp := "/tmp/zivpn-bin"
	if err := downloadFile(BinURL, tmp); err != nil {
		return fmt.Errorf("gagal download binary: %v", err)
	}
	os.Chmod(tmp, 0755)
	if err := os.Rename(tmp, BinPath); err != nil {
		// fallback copy
		runCmd("cp", tmp, BinPath)
		os.Chmod(BinPath, 0755)
	}
	fmt.Println(color(GREEN, "  ✓ Binary ZivPN berhasil diinstall"))
	return nil
}

func installConfig() error {
	os.MkdirAll(InstallDir, 0755)
	if _, err := os.Stat(ConfigPath); os.IsNotExist(err) {
		fmt.Println(color(YELLOW, "  ↓ Mengunduh config.json..."))
		if err := downloadFile(ConfigURL, ConfigPath); err != nil {
			// buat config default
			cfg := ZivConfig{Port: 1194, DNS: "8.8.8.8", LogLevel: "info"}
			data, _ := json.MarshalIndent(cfg, "", "  ")
			os.WriteFile(ConfigPath, data, 0644)
		}
		fmt.Println(color(GREEN, "  ✓ Config berhasil dipasang"))
	}
	return nil
}

func installService() error {
	svc := `[Unit]
Description=ZivPN UDP Service
After=network.target

[Service]
Type=simple
ExecStart=` + BinPath + ` -c ` + ConfigPath + `
Restart=always
RestartSec=3
User=root

[Install]
WantedBy=multi-user.target
`
	os.WriteFile(ServiceFile, []byte(svc), 0644)
	runCmd("systemctl", "daemon-reload")
	runCmd("systemctl", "enable", "zivpn")
	fmt.Println(color(GREEN, "  ✓ Service systemd berhasil dipasang"))
	return nil
}

// ─── Manajemen User ───────────────────────────────────────────────────────────

func addUser() {
	printHeader("TAMBAH AKUN UDP ZivPN")

	username := readInput("  Username         : ")
	if username == "" {
		fmt.Println(color(RED, "  ✗ Username tidak boleh kosong"))
		return
	}
	if userExists(username) {
		fmt.Println(color(RED, "  ✗ Username sudah ada"))
		return
	}

	password := readInput("  Password         : ")
	if password == "" {
		fmt.Println(color(RED, "  ✗ Password tidak boleh kosong"))
		return
	}

	daysStr := readInput("  Masa Aktif (hari) : ")
	days, err := strconv.Atoi(daysStr)
	if err != nil || days <= 0 {
		fmt.Println(color(RED, "  ✗ Hari tidak valid"))
		return
	}

	maxLoginStr := readInput("  Max Login (IP)   : ")
	maxLogin, _ := strconv.Atoi(maxLoginStr)
	if maxLogin <= 0 {
		maxLogin = 2
	}

	note := readInput("  Catatan (opsional): ")

	expDate := time.Now().AddDate(0, 0, days).Format("2006-01-02")

	user := User{
		Username:  username,
		Password:  password,
		ExpDate:   expDate,
		MaxLogin:  maxLogin,
		CreatedAt: time.Now(),
		CreatedBy: "admin",
		Note:      note,
	}

	db := loadUsers()
	db.Users = append(db.Users, user)
	saveUsers(db)

	// Tambah ke sistem (jika menggunakan auth system)
	registerSystemUser(username, password)

	// Info akun
	server := getDomain()
	port := getPort()

	printLine()
	fmt.Println(color(GREEN, "  ✓ Akun berhasil dibuat!"))
	printLine()
	fmt.Println(color(WHITE, "  ┌─ INFO AKUN ─────────────────────────────────┐"))
	fmt.Printf("  │  %-15s : %-28s│\n", "Username", username)
	fmt.Printf("  │  %-15s : %-28s│\n", "Password", password)
	fmt.Printf("  │  %-15s : %-28s│\n", "Server IP", server)
	fmt.Printf("  │  %-15s : %-28s│\n", "Port UDP", port)
	fmt.Printf("  │  %-15s : %-28s│\n", "Exp Date", expDate)
	fmt.Printf("  │  %-15s : %-28d│\n", "Max Login", maxLogin)
	fmt.Printf("  │  %-15s : %-28d│\n", "Sisa Hari", days)
	fmt.Println(color(WHITE, "  └─────────────────────────────────────────────┘"))

	// Kirim ke Telegram
	sendTelegramCreate(user, server, port)
}

func deleteUser() {
	printHeader("HAPUS AKUN UDP ZivPN")

	username := readInput("  Username yang dihapus: ")
	if !userExists(username) {
		fmt.Println(color(RED, "  ✗ User tidak ditemukan"))
		return
	}

	if !confirm(fmt.Sprintf("  Yakin hapus user %s?", color(YELLOW, username))) {
		fmt.Println(color(YELLOW, "  ↩ Dibatalkan"))
		return
	}

	db := loadUsers()
	newUsers := []User{}
	for _, u := range db.Users {
		if u.Username != username {
			newUsers = append(newUsers, u)
		}
	}
	db.Users = newUsers
	saveUsers(db)

	// Hapus dari sistem
	runCmd("userdel", "-r", username)

	fmt.Println(color(GREEN, fmt.Sprintf("  ✓ User %s berhasil dihapus", username)))
	sendTelegramDelete(username)
}

func renewUser() {
	printHeader("PERPANJANG AKUN UDP ZivPN")

	username := readInput("  Username: ")
	u := getUser(username)
	if u == nil {
		fmt.Println(color(RED, "  ✗ User tidak ditemukan"))
		return
	}

	daysStr := readInput("  Tambah hari: ")
	days, err := strconv.Atoi(daysStr)
	if err != nil || days <= 0 {
		fmt.Println(color(RED, "  ✗ Hari tidak valid"))
		return
	}

	oldExp, _ := time.Parse("2006-01-02", u.ExpDate)
	base := oldExp
	if isExpired(u.ExpDate) {
		base = time.Now()
	}
	newExp := base.AddDate(0, 0, days).Format("2006-01-02")

	db := loadUsers()
	for i, usr := range db.Users {
		if usr.Username == username {
			db.Users[i].ExpDate = newExp
			break
		}
	}
	saveUsers(db)

	fmt.Println(color(GREEN, fmt.Sprintf("  ✓ Akun diperpanjang sampai %s", newExp)))
	sendTelegramRenew(username, newExp)
}

func listUsers() {
	printHeader("DAFTAR AKUN UDP ZivPN")
	db := loadUsers()

	if len(db.Users) == 0 {
		fmt.Println(color(YELLOW, "  ↳ Belum ada akun"))
		return
	}

	fmt.Printf("  %-18s %-12s %-10s %-5s %s\n",
		color(BOLD, "Username"), color(BOLD, "Exp Date"), color(BOLD, "Status"), color(BOLD, "Hari"), color(BOLD, "MaxIP"))
	printLine()

	for _, u := range db.Users {
		status := color(GREEN, "Aktif")
		days := daysLeft(u.ExpDate)
		if isExpired(u.ExpDate) {
			status = color(RED, "Expired")
			days = 0
		} else if days <= 3 {
			status = color(YELLOW, "Segera")
		}
		fmt.Printf("  %-18s %-12s %-10s %-5d %d\n",
			u.Username, u.ExpDate, status, days, u.MaxLogin)
	}
	printLine()
	fmt.Printf("  Total: %d akun\n", len(db.Users))
}

func checkUser() {
	printHeader("CEK AKUN UDP ZivPN")

	username := readInput("  Username: ")
	u := getUser(username)
	if u == nil {
		fmt.Println(color(RED, "  ✗ User tidak ditemukan"))
		return
	}

	server := getDomain()
	port := getPort()
	days := daysLeft(u.ExpDate)

	status := color(GREEN, "✓ AKTIF")
	if isExpired(u.ExpDate) {
		status = color(RED, "✗ EXPIRED")
		days = 0
	}

	printLine()
	fmt.Println(color(WHITE, "  ┌─ DETAIL AKUN ───────────────────────────────┐"))
	fmt.Printf("  │  %-15s : %-28s│\n", "Username", u.Username)
	fmt.Printf("  │  %-15s : %-28s│\n", "Password", u.Password)
	fmt.Printf("  │  %-15s : %-28s│\n", "Server IP", server)
	fmt.Printf("  │  %-15s : %-28s│\n", "Port UDP", port)
	fmt.Printf("  │  %-15s : %-28s│\n", "Exp Date", u.ExpDate)
	fmt.Printf("  │  %-15s : %-28d│\n", "Sisa Hari", days)
	fmt.Printf("  │  %-15s : %-28d│\n", "Max Login", u.MaxLogin)
	fmt.Printf("  │  %-15s : %-28s│\n", "Status", status)
	if u.Note != "" {
		fmt.Printf("  │  %-15s : %-28s│\n", "Catatan", u.Note)
	}
	fmt.Println(color(WHITE, "  └─────────────────────────────────────────────┘"))
}

func cleanExpired() {
	printHeader("HAPUS AKUN EXPIRED")
	db := loadUsers()
	count := 0
	active := []User{}
	for _, u := range db.Users {
		if isExpired(u.ExpDate) {
			runCmd("userdel", "-r", u.Username)
			fmt.Printf("  ✓ Dihapus: %s (exp: %s)\n", color(RED, u.Username), u.ExpDate)
			count++
		} else {
			active = append(active, u)
		}
	}
	db.Users = active
	saveUsers(db)
	fmt.Printf("\n  %s %d akun expired dihapus\n", color(GREEN, "✓"), count)
}

// ─── Service Control ──────────────────────────────────────────────────────────

func serviceStatus() {
	printHeader("STATUS SERVICE ZivPN")
	out, _ := runCmdOutput("systemctl", "is-active", "zivpn")
	if out == "active" {
		fmt.Println(color(GREEN, "  ● Service: AKTIF (running)"))
	} else {
		fmt.Println(color(RED, "  ● Service: TIDAK AKTIF ("+out+")"))
	}

	fmt.Println()
	fmt.Printf("  %-15s : %s\n", "Binary", BinPath)
	fmt.Printf("  %-15s : %s\n", "Config", ConfigPath)
	fmt.Printf("  %-15s : %s\n", "Domain/IP", getDomain())
	fmt.Printf("  %-15s : %s\n", "Port UDP", getPort())
}

func startService()   { runCmd("systemctl", "start", "zivpn"); fmt.Println(color(GREEN, "  ✓ Service dimulai")) }
func stopService()    { runCmd("systemctl", "stop", "zivpn"); fmt.Println(color(YELLOW, "  ✓ Service dihentikan")) }
func restartService() { runCmd("systemctl", "restart", "zivpn"); fmt.Println(color(GREEN, "  ✓ Service direstart")) }

// ─── Bot Telegram ─────────────────────────────────────────────────────────────

func loadBotConfig() BotConfig {
	data, err := os.ReadFile(BotCfgFile)
	if err != nil {
		return BotConfig{}
	}
	var cfg BotConfig
	json.Unmarshal(data, &cfg)
	return cfg
}

func saveBotConfig(cfg BotConfig) {
	data, _ := json.MarshalIndent(cfg, "", "  ")
	os.WriteFile(BotCfgFile, data, 0600)
}

func setupBot() {
	printHeader("SETUP BOT TELEGRAM")

	fmt.Println(color(CYAN, "  Cara mendapatkan token:"))
	fmt.Println("   1. Buka @BotFather di Telegram")
	fmt.Println("   2. Ketik /newbot → ikuti instruksi")
	fmt.Println("   3. Salin token yang diberikan")
	fmt.Println()

	token := readInput("  Bot Token : ")
	chatID := readInput("  Chat ID   : ")

	if token == "" || chatID == "" {
		fmt.Println(color(RED, "  ✗ Token dan Chat ID tidak boleh kosong"))
		return
	}

	cfg := BotConfig{Token: token, ChatID: chatID}
	saveBotConfig(cfg)

	// Test kirim pesan
	msg := "✅ *ZivPN Bot Aktif!*\nBot berhasil dikonfigurasi dan siap digunakan."
	if err := sendTelegram(cfg, msg); err != nil {
		fmt.Println(color(RED, "  ✗ Gagal kirim test message: "+err.Error()))
	} else {
		fmt.Println(color(GREEN, "  ✓ Bot berhasil dikonfigurasi, pesan test terkirim!"))
	}
}

func sendTelegram(cfg BotConfig, msg string) error {
	if cfg.Token == "" || cfg.ChatID == "" {
		return nil
	}
	url := fmt.Sprintf("https://api.telegram.org/bot%s/sendMessage", cfg.Token)
	payload := fmt.Sprintf(`{"chat_id":"%s","text":"%s","parse_mode":"Markdown"}`,
		cfg.ChatID, escapeTG(msg))
	resp, err := http.Post(url, "application/json", strings.NewReader(payload))
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	return nil
}

func escapeTG(s string) string {
	s = strings.ReplaceAll(s, `"`, `\"`)
	return s
}

func sendTelegramCreate(u User, server, port string) {
	cfg := loadBotConfig()
	if cfg.Token == "" {
		return
	}
	msg := fmt.Sprintf(`🆕 *AKUN BARU DIBUAT*
━━━━━━━━━━━━━━━━━━━
👤 Username  : %s
🔑 Password  : %s
🌐 Host/IP   : %s
🔌 Port UDP  : %s
📅 Exp Date  : %s
⏳ Masa Aktif: %d Hari
👥 Max Login : %d
━━━━━━━━━━━━━━━━━━━
🤖 ZivPN Manager v%s`,
		u.Username, u.Password, server, port,
		u.ExpDate, daysLeft(u.ExpDate), u.MaxLogin, Version)
	sendTelegram(cfg, msg)
}

func sendTelegramDelete(username string) {
	cfg := loadBotConfig()
	if cfg.Token == "" {
		return
	}
	msg := fmt.Sprintf("🗑️ *AKUN DIHAPUS*\n👤 Username: %s\n⏰ Waktu: %s",
		username, time.Now().Format("2006-01-02 15:04:05"))
	sendTelegram(cfg, msg)
}

func sendTelegramRenew(username, newExp string) {
	cfg := loadBotConfig()
	if cfg.Token == "" {
		return
	}
	msg := fmt.Sprintf("🔄 *AKUN DIPERPANJANG*\n👤 Username: %s\n📅 Exp Baru: %s",
		username, newExp)
	sendTelegram(cfg, msg)
}

// ─── Utilitas ─────────────────────────────────────────────────────────────────

func getServerIP() string {
	out, err := runCmdOutput("curl", "-s", "ifconfig.me")
	if err != nil || out == "" {
		out, _ = runCmdOutput("hostname", "-I")
		fields := strings.Fields(out)
		if len(fields) > 0 {
			return fields[0]
		}
	}
	return out
}

func getPort() string {
	data, err := os.ReadFile(ConfigPath)
	if err != nil {
		return "1194"
	}
	re := regexp.MustCompile(`"port"\s*:\s*(\d+)`)
	m := re.FindStringSubmatch(string(data))
	if len(m) > 1 {
		return m[1]
	}
	return "1194"
}

func registerSystemUser(username, password string) {
	// Buat user sistem untuk autentikasi PAM
	exec.Command("useradd", "-M", "-s", "/bin/false", username).Run()
	cmd := exec.Command("chpasswd")
	cmd.Stdin = strings.NewReader(fmt.Sprintf("%s:%s", username, password))
	cmd.Run()
}

func changePort() {
	printHeader("GANTI PORT UDP")

	portStr := readInput("  Port baru (1-65535): ")
	port, err := strconv.Atoi(portStr)
	if err != nil || port < 1 || port > 65535 {
		fmt.Println(color(RED, "  ✗ Port tidak valid"))
		return
	}

	data, _ := os.ReadFile(ConfigPath)
	re := regexp.MustCompile(`"port"\s*:\s*\d+`)
	newData := re.ReplaceAll(data, []byte(fmt.Sprintf(`"port": %d`, port)))
	os.WriteFile(ConfigPath, newData, 0644)

	restartService()
	fmt.Println(color(GREEN, fmt.Sprintf("  ✓ Port berhasil diganti ke %d", port)))
}

// ─── Manajemen Domain ─────────────────────────────────────────────────────────

func loadDomain() DomainConfig {
	data, err := os.ReadFile(DomainFile)
	if err != nil {
		return DomainConfig{}
	}
	var d DomainConfig
	json.Unmarshal(data, &d)
	return d
}

func saveDomain(d DomainConfig) {
	data, _ := json.MarshalIndent(d, "", "  ")
	os.WriteFile(DomainFile, data, 0644)
}

func getDomain() string {
	d := loadDomain()
	if d.Domain != "" {
		return d.Domain
	}
	return getServerIP()
}

func changeDomain() {
	printHeader("GANTI DOMAIN / HOST")

	current := loadDomain()
	if current.Domain != "" {
		fmt.Printf("  Domain saat ini : %s\n", color(CYAN, current.Domain))
		fmt.Printf("  Diperbarui      : %s\n\n", current.UpdatedAt.Format("2006-01-02 15:04:05"))
	} else {
		fmt.Println(color(YELLOW, "  ↳ Belum ada domain, menggunakan IP server"))
		fmt.Printf("  IP Server       : %s\n\n", color(CYAN, getServerIP()))
	}

	fmt.Println(color(WHITE, "  Contoh: vpn.example.com atau sub.domain.net"))
	domain := readInput("  Domain baru     : ")

	if domain == "" {
		fmt.Println(color(RED, "  ✗ Domain tidak boleh kosong"))
		return
	}

	// Validasi format domain sederhana
	domainRe := regexp.MustCompile(`^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$`)
	if !domainRe.MatchString(domain) {
		fmt.Println(color(RED, "  ✗ Format domain tidak valid"))
		return
	}

	// Resolve domain → IP (opsional cek)
	fmt.Printf(color(YELLOW, "  ⟳ Mengecek resolusi domain %s...\n"), domain)
	resolvedIP, err := runCmdOutput("getent", "hosts", domain)
	if err != nil || resolvedIP == "" {
		fmt.Println(color(YELLOW, "  ⚠ Domain tidak dapat di-resolve (mungkin DNS belum propagasi)"))
		if !confirm("  Tetap simpan domain ini?") {
			fmt.Println(color(YELLOW, "  ↩ Dibatalkan"))
			return
		}
	} else {
		fields := strings.Fields(resolvedIP)
		if len(fields) > 0 {
			fmt.Printf("  ✓ Domain resolve ke: %s\n", color(GREEN, fields[0]))
		}
	}

	oldDomain := current.Domain
	if oldDomain == "" {
		oldDomain = getServerIP()
	}

	// Update config.json jika ada field domain/host
	data, _ := os.ReadFile(ConfigPath)
	reHost := regexp.MustCompile(`"(host|domain|server)"\s*:\s*"[^"]+"`)
	if reHost.Match(data) {
		newData := reHost.ReplaceAll(data, []byte(fmt.Sprintf(`"host": "%s"`, domain)))
		os.WriteFile(ConfigPath, newData, 0644)
	}

	cfg := DomainConfig{
		Domain:    domain,
		UpdatedAt: time.Now(),
	}
	saveDomain(cfg)

	restartService()

	printLine()
	fmt.Println(color(GREEN, "  ✓ Domain berhasil diperbarui!"))
	fmt.Printf("  %-15s : %s\n", "Domain Lama", color(RED, oldDomain))
	fmt.Printf("  %-15s : %s\n", "Domain Baru", color(GREEN, domain))
	printLine()

	// Notifikasi Telegram
	sendTelegramDomain(oldDomain, domain)
}

func sendTelegramDomain(old, newDomain string) {
	cfg := loadBotConfig()
	if cfg.Token == "" {
		return
	}
	msg := fmt.Sprintf("🌐 *DOMAIN DIPERBARUI*\n🔴 Lama : %s\n🟢 Baru : %s\n⏰ Waktu: %s",
		old, newDomain, time.Now().Format("2006-01-02 15:04:05"))
	sendTelegram(cfg, msg)
}

// ─── Instalasi ────────────────────────────────────────────────────────────────

func install() {
	printHeader("INSTALASI UDP ZivPN")

	checkRoot()

	fmt.Println(color(CYAN, "  Memulai instalasi..."))
	os.MkdirAll(InstallDir, 0755)

	// 1. Binary
	if err := installBin(); err != nil {
		fmt.Println(color(RED, "  ✗ "+err.Error()))
		os.Exit(1)
	}

	// 2. Config
	installConfig()

	// 3. DB user
	if _, err := os.Stat(UserDB); os.IsNotExist(err) {
		saveUsers(UserDB{Users: []User{}})
	}

	// 4. Service
	installService()

	// 5. Start
	startService()

	printLine()
	fmt.Println(color(GREEN, "  ✓ ZivPN berhasil diinstall!"))
	fmt.Printf("  %-15s : %s\n", "Domain/IP", getDomain())
	fmt.Printf("  %-15s : %s\n", "Port UDP", getPort())
	fmt.Printf("  %-15s : %s\n", "Binary", BinPath)
	fmt.Printf("  %-15s : %s\n", "Config", ConfigPath)
	printLine()
	fmt.Println(color(YELLOW, "  Tips: Jalankan 'zivpn-manager setup-bot' untuk konfigurasi Telegram"))
}

func uninstall() {
	printHeader("UNINSTALL UDP ZivPN")

	if !confirm("  Yakin ingin uninstall ZivPN?") {
		return
	}

	runCmd("systemctl", "stop", "zivpn")
	runCmd("systemctl", "disable", "zivpn")
	os.Remove(ServiceFile)
	runCmd("systemctl", "daemon-reload")
	os.Remove(BinPath)
	os.RemoveAll(InstallDir)

	fmt.Println(color(GREEN, "  ✓ ZivPN berhasil diuninstall"))
}

// ─── Info VPS ─────────────────────────────────────────────────────────────────

func getVPSInfo() (os_, kernel, cpu, ram, disk, uptime string) {
	os_, _ = runCmdOutput("bash", "-c", `cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2`)
	if os_ == "" {
		os_, _ = runCmdOutput("uname", "-s")
	}
	kernel, _ = runCmdOutput("uname", "-r")
	cpu, _ = runCmdOutput("bash", "-c", `nproc 2>/dev/null || grep -c processor /proc/cpuinfo`)
	ram, _ = runCmdOutput("bash", "-c", `free -m 2>/dev/null | awk '/^Mem/{printf "%s MB / %s MB", $3, $2}'`)
	disk, _ = runCmdOutput("bash", "-c", `df -h / 2>/dev/null | awk 'NR==2{printf "%s / %s (%s)", $3, $2, $5}'`)
	uptime, _ = runCmdOutput("bash", "-c", `uptime -p 2>/dev/null | sed 's/up //'`)
	if uptime == "" {
		uptime, _ = runCmdOutput("bash", "-c", `cat /proc/uptime | awk '{s=$1; d=int(s/86400); h=int((s%86400)/3600); m=int((s%3600)/60); printf "%dd %dh %dm", d,h,m}'`)
	}
	return
}

func getServiceStatus() string {
	out, _ := runCmdOutput("systemctl", "is-active", "zivpn")
	if strings.TrimSpace(out) == "active" {
		return color(GREEN, "● AKTIF")
	}
	return color(RED, "● MATI")
}

func getTotalUsers() string {
	db := loadUsers()
	total := len(db.Users)
	active := 0
	expired := 0
	for _, u := range db.Users {
		if isExpired(u.ExpDate) {
			expired++
		} else {
			active++
		}
	}
	return fmt.Sprintf("%d total  %s aktif  %s expired",
		total, color(GREEN, strconv.Itoa(active)), color(RED, strconv.Itoa(expired)))
}

// ─── Menu Utama ───────────────────────────────────────────────────────────────

func showLogo() {
	lines := []string{
		`  _____     _____   __   __   _____     _   _  `,
		` |___  /   |_   _|  \ \ / /  |  __ \   | \ | | `,
		`    / /      | |     \ V /   | |__) |  |  \| | `,
		`   / /__    _| |_     \_/    |  ___/   | |\ |  `,
		`  /_____|  |_____|          |_|        |_| \_|  `,
	}
	for _, line := range lines {
		out := ""
		for i, ch := range line {
			if i%2 == 0 {
				out += CYAN + string(ch)
			} else {
				out += PURPLE + string(ch)
			}
		}
		fmt.Println(out + RESET)
	}
	sepLine := ""
	for i := 0; i < 50; i++ {
		if i%2 == 0 {
			sepLine += color(CYAN, "=")
		} else {
			sepLine += color(PURPLE, "=")
		}
	}
	fmt.Println(sepLine)
	fmt.Println(color(PURPLE, "         Selamat Datang di ZIVPN Manager"))
	fmt.Println(sepLine)
}

func showVPSInfo() {
	osName, kernel, cpu, ram, disk, uptime := getVPSInfo()
	dom := getDomain()
	port := getPort()
	svcStatus := getServiceStatus()
	userInfo := getTotalUsers()

	w := 55
	bar := color(CYAN, strings.Repeat("─", w))
	fmt.Println(bar)
	fmt.Println(color(CYAN, "│") + color(BOLD+WHITE, "                  INFO VPS                    ") + color(CYAN, "│"))
	fmt.Println(bar)
	infoRow := func(label, val string) {
		fmt.Printf("%s %s%-13s%s : %-34s%s\n",
			color(CYAN, "│"), YELLOW, label, RESET, val, color(CYAN, "│"))
	}
	infoRow("OS", osName)
	infoRow("Kernel", kernel)
	infoRow("CPU Cores", cpu+" Core")
	infoRow("RAM", ram)
	infoRow("Disk", disk)
	infoRow("Uptime", uptime)
	fmt.Println(bar)
	infoRow("Host/Domain", color(CYAN, dom))
	infoRow("Port UDP", color(CYAN, port))
	infoRow("Service", svcStatus)
	infoRow("Akun", userInfo)
	fmt.Println(bar)
}

func showMenu() {
	fmt.Print("\033[2J\033[H") // clear screen
	showLogo()
	showVPSInfo()

	// ── 2 Kolom Menu ──────────────────────────────────────────
	w := 55
	bar := color(CYAN, strings.Repeat("─", w))

	menuRow := func(n1, l1, c1, n2, l2, c2 string) {
		left := fmt.Sprintf(" %s%-2s%s %-19s", c1, n1, RESET, l1)
		right := fmt.Sprintf(" %s%-2s%s %-19s", c2, n2, RESET, l2)
		fmt.Printf("%s%-28s%s%-28s%s\n",
			color(CYAN, "│"), left,
			color(CYAN, "│"), right,
			color(CYAN, "│"))
	}
	sectionHdr := func(title string) {
		fmt.Println(bar)
		padded := fmt.Sprintf(" ── %-50s", title)
		fmt.Printf("%s%s%s\n", color(CYAN, "│"), color(WHITE, padded), color(CYAN, "│"))
	}

	sectionHdr("MANAJEMEN AKUN")
	menuRow("1", "Tambah Akun", YELLOW, "2", "Hapus Akun", YELLOW)
	menuRow("3", "Perpanjang Akun", YELLOW, "4", "Lihat Semua Akun", YELLOW)
	menuRow("5", "Cek Akun", YELLOW, "6", "Hapus Expired", YELLOW)

	sectionHdr("SERVICE & KONFIGURASI")
	menuRow("7", "Status Service", GREEN, "8", "Start Service", GREEN)
	menuRow("9", "Stop Service", GREEN, "10", "Restart Service", GREEN)
	menuRow("11", "Ganti Port", GREEN, "12", "Ganti Domain/Host", GREEN)

	sectionHdr("TELEGRAM & SISTEM")
	menuRow("13", "Setup Bot Telegram", BLUE, "14", "Install ZivPN", RED)
	menuRow("15", "Uninstall ZivPN", RED, "0", "Keluar", RED)

	fmt.Println(bar)
}

func menuLoop() {
	for {
		showMenu()
		choice := readInput("\n  Pilih menu [0-15]: ")

		switch choice {
		case "1":
			addUser()
		case "2":
			deleteUser()
		case "3":
			renewUser()
		case "4":
			listUsers()
		case "5":
			checkUser()
		case "6":
			cleanExpired()
		case "7":
			serviceStatus()
		case "8":
			startService()
		case "9":
			stopService()
		case "10":
			restartService()
		case "11":
			changePort()
		case "12":
			changeDomain()
		case "13":
			setupBot()
		case "14":
			install()
		case "15":
			uninstall()
		case "0":
			fmt.Println(color(CYAN, "\n  Sampai jumpa! 👋\n"))
			os.Exit(0)
		default:
			fmt.Println(color(RED, "  ✗ Pilihan tidak valid"))
		}

		fmt.Print(color(YELLOW, "\n  Tekan Enter untuk lanjut..."))
		bufio.NewReader(os.Stdin).ReadString('\n')
	}
}

// ─── Entry Point ──────────────────────────────────────────────────────────────

func main() {
	// Handle argumen CLI
	if len(os.Args) > 1 {
		switch os.Args[1] {
		case "install":
			checkRoot()
			install()
		case "add":
			checkRoot()
			addUser()
		case "del":
			checkRoot()
			deleteUser()
		case "renew":
			checkRoot()
			renewUser()
		case "list":
			listUsers()
		case "check":
			checkUser()
		case "clean":
			checkRoot()
			cleanExpired()
		case "status":
			serviceStatus()
		case "start":
			checkRoot()
			startService()
		case "stop":
			checkRoot()
			stopService()
		case "restart":
			checkRoot()
			restartService()
		case "setup-bot":
			checkRoot()
			setupBot()
		case "domain":
			checkRoot()
			changeDomain()
		case "uninstall":
			checkRoot()
			uninstall()
		case "version":
			fmt.Println("ZivPN Manager v" + Version)
		case "help":
			showHelp()
		default:
			fmt.Println(color(RED, "Perintah tidak dikenal: "+os.Args[1]))
			showHelp()
		}
		return
	}

	// Mode interaktif
	checkRoot()
	menuLoop()
}

func showHelp() {
	fmt.Println(color(BOLD+CYAN, "\nUDP ZivPN Manager v"+Version))
	fmt.Println(color(WHITE, "\nPenggunaan: zivpn-manager [perintah]\n"))
	cmds := [][]string{
		{"install", "Install ZivPN"},
		{"add", "Tambah akun baru"},
		{"del", "Hapus akun"},
		{"renew", "Perpanjang akun"},
		{"list", "Lihat semua akun"},
		{"check", "Cek detail akun"},
		{"clean", "Hapus akun expired"},
		{"status", "Status service"},
		{"start", "Start service"},
		{"stop", "Stop service"},
		{"restart", "Restart service"},
		{"setup-bot", "Setup bot Telegram"},
		{"domain", "Ganti domain / host"},
		{"uninstall", "Uninstall ZivPN"},
		{"version", "Versi script"},
	}
	for _, c := range cmds {
		fmt.Printf("  %-15s %s\n", color(YELLOW, c[0]), c[1])
	}
	fmt.Println()

	// filepath dipakai biar tidak unused import
	_ = filepath.Join(InstallDir, "")
}
