#!/usr/bin/env python3

import os
import subprocess
import datetime
import json
import shutil
from pathlib import Path
from colorama import init, Fore, Style
import time

# Colorama’yı başlat
init()

# Renk tanımları
RED = Fore.RED
GREEN = Fore.GREEN
YELLOW = Fore.YELLOW
BLUE = Fore.BLUE
CYAN = Fore.CYAN
RESET = Style.RESET_ALL

# Log dosyası
LOG_FILE = "bug_bounty_scan.log"
with open(LOG_FILE, "w") as f:
    f.write(f"[{datetime.datetime.now()}] Script başlatıldı\n")

# Çalışma dizini
WORK_DIR = Path("/workspaces/bug_bounty_work")
OUTPUT_DIR = WORK_DIR / f"bug_bounty_{datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}"

# Hata kontrolü fonksiyonu
def check_error(result, message):
    if result.returncode != 0:
        error_msg = f"{RED}Hata: {message}{RESET}"
        print(error_msg)
        with open(LOG_FILE, "a") as f:
            f.write(f"[{datetime.datetime.now()}] {message}: {result.stderr.decode()}\n")
        exit(1)

# Dosya kontrolü fonksiyonu
def check_file(file_path):
    file_path = Path(file_path)
    if not file_path.exists() or file_path.stat().st_size == 0:
        print(f"{YELLOW}[*] Uyarı: {file_path} boş veya mevcut değil, oluşturuluyor...{RESET}")
        with open(LOG_FILE, "a") as f:
            f.write(f"[{datetime.datetime.now()}] Uyarı: {file_path} boş veya mevcut değil\n")
        file_path.touch()

# İlerleme çubuğu fonksiyonu
def progress_bar(progress, total, width=50):
    percent = (progress / total) * 100
    filled = int(width * progress // total)
    bar = "#" * filled + "-" * (width - filled)
    print(f"\r{CYAN}[{bar}] {percent:.1f}%{RESET}", end="", flush=True)

# Araç kontrolü ve kurulum fonksiyonu
def check_and_install_tools():
    print(f"{YELLOW}[*] Gerekli araçlar kontrol ediliyor...{RESET}")
    with open(LOG_FILE, "a") as f:
        f.write(f"[{datetime.datetime.now()}] Gerekli araçlar kontrol ediliyor\n")

    # Bağımlılıklar
    print(f"{YELLOW}[*] Bağımlılıklar kontrol ediliyor...{RESET}")
    result = subprocess.run("sudo apt update && sudo apt install -y golang git python3 python3-pip figlet chromium-browser", shell=True, capture_output=True)
    check_error(result, "Bağımlılıklar kurulamadı")

    # Python bağımlılıkları
    result = subprocess.run("pip3 install colorama arjun", shell=True, capture_output=True)
    check_error(result, "Python bağımlılıkları kurulamadı")

    # Go tabanlı araçlar
    go_tools = ["subfinder", "katana", "httpx", "nuclei", "waybackurls", "gf", "dalfox", "anew", "getjs", "gau", "hakrawler"]
    total_tools = len(go_tools)
    for i, tool in enumerate(go_tools, 1):
        progress_bar(i, total_tools)
        if not shutil.which(tool):
            print(f"\n{YELLOW}[*] {tool} bulunamadı, kuruluyor...{RESET}")
            with open(LOG_FILE, "a") as f:
                f.write(f"[{datetime.datetime.now()}] {tool} kuruluyor\n")
            if tool == "subfinder":
                cmd = "go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
            elif tool == "katana":
                cmd = "go install -v github.com/projectdiscovery/katana/cmd/katana@latest"
            elif tool == "httpx":
                cmd = "go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest"
            elif tool == "nuclei":
                cmd = "go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
            elif tool == "waybackurls":
                cmd = "go install github.com/tomnomnom/waybackurls@latest"
            elif tool == "gf":
                cmd = "go install github.com/tomnomnom/gf@latest"
            elif tool == "dalfox":
                cmd = "go install github.com/hahwul/dalfox/v2@latest"
            elif tool == "anew":
                cmd = "go install github.com/tomnomnom/anew@latest"
            elif tool == "getjs":
                cmd = "go install github.com/003random/getJS@latest"
            elif tool == "gau":
                cmd = "go install github.com/lc/gau/v2/cmd/gau@latest"
            elif tool == "hakrawler":
                cmd = "go install github.com/hakluke/hakrawler@latest"
            result = subprocess.run(cmd, shell=True, capture_output=True)
            check_error(result, f"{tool} kurulumu başarısız")
            result = subprocess.run(f"mv ~/go/bin/{tool} /usr/local/bin/", shell=True, capture_output=True)
            check_error(result, f"{tool} taşınırken hata")
    print(f"\n{GREEN}[+] Tüm araçlar kuruldu{RESET}")

    # GF desenleri
    gf_dir = Path.home() / ".gf"
    if not gf_dir.exists():
        print(f"{YELLOW}[*] GF desenleri indiriliyor...{RESET}")
        result = subprocess.run(f"git clone https://github.com/1ndianl33t/Gf-Patterns {WORK_DIR}/Gf-Patterns", shell=True, capture_output=True)
        check_error(result, "GF desenleri indirilemedi")
        gf_dir.mkdir(parents=True, exist_ok=True)
        result = subprocess.run(f"cp {WORK_DIR}/Gf-Patterns/*.json {gf_dir}/", shell=True, capture_output=True)
        check_error(result, "GF desenleri kopyalanamadı")
        shutil.rmtree(f"{WORK_DIR}/Gf-Patterns")

    # Nuclei şablonları
    nuclei_dir = Path.home() / "nuclei-templates"
    if not nuclei_dir.exists():
        print(f"{YELLOW}[*] Nuclei şablonları indiriliyor...{RESET}")
        result = subprocess.run(f"git clone https://github.com/projectdiscovery/nuclei-templates {nuclei_dir}", shell=True, capture_output=True)
        check_error(result, "Nuclei şablonları indirilemedi")
    else:
        print(f"{YELLOW}[*] Nuclei şablonları güncelleniyor...{RESET}")
        result = subprocess.run(f"cd {nuclei_dir} && git pull", shell=True, capture_output=True)
        check_error(result, "Nuclei şablonları güncellenemedi")

    # API kelime listesi
    wordlist = WORK_DIR / "api_wordlist.txt"
    if not wordlist.exists():
        print(f"{YELLOW}[*] API kelime listesi indiriliyor...{RESET}")
        result = subprocess.run(f"wget -q https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/api/words.txt -O {wordlist}", shell=True, capture_output=True)
        check_error(result, "API kelime listesi indirilemedi")

    print(f"{GREEN}[+] Tüm araçlar ve eklentiler hazır!{RESET}")
    with open(LOG_FILE, "a") as f:
        f.write(f"[{datetime.datetime.now()}] Tüm araçlar hazır\n")

# JSON çıktı fonksiyonu
def generate_json_output(output_dir):
    json_file = output_dir / "results.json"
    data = {
        "domain": DOMAIN,
        "timestamp": str(datetime.datetime.now()),
        "api_endpoints": [],
        "sensitive_data": [],
        "js_endpoints": [],
        "hidden_parameters": [],
        "vulnerabilities": [],
        "xss_vulnerabilities": []
    }
    verified_file = output_dir / "verified_api_results.txt"
    if verified_file.exists() and verified_file.stat().st_size > 0:
        with open(verified_file, "r") as f:
            data["api_endpoints"] = [line.split()[0] for line in f]
    api_keys_file = output_dir / "api_keys.txt"
    if api_keys_file.exists() and api_keys_file.stat().st_size > 0:
        with open(api_keys_file, "r") as f:
            data["sensitive_data"] = [line.strip() for line in f]
    js_file = output_dir / "js_endpoints.txt"
    if js_file.exists() and js_file.stat().st_size > 0:
        with open(js_file, "r") as f:
            data["js_endpoints"] = [line.strip() for line in f]
    arjun_file = output_dir / "arjun_results.txt"
    if arjun_file.exists() and arjun_file.stat().st_size > 0:
        with open(arjun_file, "r") as f:
            data["hidden_parameters"] = [line.strip() for line in f]
    nuclei_file = output_dir / "nuclei_results.txt"
    if nuclei_file.exists() and nuclei_file.stat().st_size > 0:
        with open(nuclei_file, "r") as f:
            data["vulnerabilities"] = [line.strip() for line in f]
    dalfox_file = output_dir / "dalfox_results.txt"
    if dalfox_file.exists() and dalfox_file.stat().st_size > 0:
        with open(dalfox_file, "r") as f:
            data["xss_vulnerabilities"] = [line.strip() for line in f]
    with open(json_file, "w") as f:
        json.dump(data, f, indent=2)

# Çalışma dizini oluştur
WORK_DIR.mkdir(parents=True, exist_ok=True)

# Banner
if shutil.which("figlet"):
    print(f"{GREEN}")
    subprocess.run("figlet -f standard 'Bug Bounty'", shell=True)
    print(f"{RESET}")
else:
    print(f"{BLUE}========================================{RESET}")
    print(f"{GREEN} Codespaces Bug Bounty Tarama Scripti{RESET}")
    print(f"{BLUE}========================================{RESET}")
print(f"{YELLOW}Yazar: losmanchos{RESET}")
print(f"{RED}Uyarı: Yalnızca izinli sistemlerde kullanın!{RESET}\n")

# Hedef domaini al
DOMAIN = input(f"{BLUE}[*] Hedef domaini girin (örn. example.com): {RESET}")
if not DOMAIN:
    print(f"{RED}Hata: Domain girilmedi!{RESET}")
    with open(LOG_FILE, "a") as f:
        f.write(f"[{datetime.datetime.now()}] Hata: Domain girilmedi\n")
    exit(1)
print(f"{GREEN}[+] Hedef: {DOMAIN}{RESET}\n")
with open(LOG_FILE, "a") as f:
    f.write(f"[{datetime.datetime.now()}] Hedef: {DOMAIN}\n")

# Araçları kontrol et ve kur
check_and_install_tools()

# Çıktı dizini oluştur
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Adım 1: Subdomain tarama
print(f"{YELLOW}[*] Subdomain taraması başlatılıyor...{RESET}")
result = subprocess.run(f"subfinder -d {DOMAIN} -o {OUTPUT_DIR}/subdomains.txt -silent -nW", shell=True, capture_output=True)
check_error(result, "Subdomain taraması başarısız")
check_file(f"{OUTPUT_DIR}/subdomains.txt")
with open(f"{OUTPUT_DIR}/subdomains.txt", "r") as f:
    subdomain_count = len(f.readlines())
print(f"{GREEN}[+] {subdomain_count} subdomain bulundu{RESET}\n")

# Adım 2: Katana ile API ve URL keşfi
print(f"{YELLOW}[*] Katana ile API ve URL taraması başlatılıyor...{RESET}")
result = subprocess.run(f"katana -u {OUTPUT_DIR}/subdomains.txt -o {OUTPUT_DIR}/katana_results.txt -c 50 -d 5 -f url -ef css,js,png,jpg,jpeg,gif -silent", shell=True, capture_output=True)
check_error(result, "Katana taraması başarısız")
check_file(f"{OUTPUT_DIR}/katana_results.txt")

# Adım 3: Waybackurls ve Gau ile geçmiş URL’ler
print(f"{YELLOW}[*] Geçmiş URL’ler taranıyor (Waybackurls ve Gau)...{RESET}")
result = subprocess.run(f"waybackurls {DOMAIN} | anew {OUTPUT_DIR}/wayback_urls.txt", shell=True, capture_output=True)
check_error(result, "Waybackurls taraması başarısız")
result = subprocess.run(f"gau {DOMAIN} --subs | anew {OUTPUT_DIR}/gau_urls.txt", shell=True, capture_output=True)
check_error(result, "Gau taraması başarısız")
check_file(f"{OUTPUT_DIR}/wayback_urls.txt")
check_file(f"{OUTPUT_DIR}/gau_urls.txt")

# Adım 4: Hakrawler ile web tarama
print(f"{YELLOW}[*] Hakrawler ile web taraması başlatılıyor...{RESET}")
result = subprocess.run(f"cat {OUTPUT_DIR}/subdomains.txt | hakrawler -depth 3 -plain > {OUTPUT_DIR}/hakrawler_results.txt", shell=True, capture_output=True)
check_error(result, "Hakrawler taraması başarısız")
check_file(f"{OUTPUT_DIR}/hakrawler_results.txt")

# API uç noktalarını birleştir ve filtrele
print(f"{YELLOW}[*] API uç noktaları birleştiriliyor...{RESET}")
result = subprocess.run(f"cat {OUTPUT_DIR}/katana_results.txt {OUTPUT_DIR}/wayback_urls.txt {OUTPUT_DIR}/gau_urls.txt {OUTPUT_DIR}/hakrawler_results.txt | grep -E '/api|/v1|/graphql|/swagger|/docs' | sort -u | anew {OUTPUT_DIR}/api_urls.txt", shell=True, capture_output=True)
check_error(result, "API uç noktaları birleştirilemedi")
check_file(f"{OUTPUT_DIR}/api_urls.txt")
with open(f"{OUTPUT_DIR}/api_urls.txt", "r") as f:
    api_count = len(f.readlines())
print(f"{GREEN}[+] {api_count} potansiyel API uç noktası bulundu{RESET}\n")

# Adım 5: GetJS ile JavaScript analizi
print(f"{YELLOW}[*] JavaScript dosyaları analiz ediliyor...{RESET}")
result = subprocess.run(f"cat {OUTPUT_DIR}/katana_results.txt {OUTPUT_DIR}/wayback_urls.txt {OUTPUT_DIR}/gau_urls.txt | grep '\.js$' | getJS --complete > {OUTPUT_DIR}/js_files.txt", shell=True, capture_output=True)
check_error(result, "GetJS taraması başarısız")
check_file(f"{OUTPUT_DIR}/js_files.txt")
result = subprocess.run(f"cat {OUTPUT_DIR}/js_files.txt | gf endpoints | anew {OUTPUT_DIR}/js_endpoints.txt", shell=True, capture_output=True)
check_error(result, "JS uç noktaları çıkarılamadı")
check_file(f"{OUTPUT_DIR}/js_endpoints.txt")
with open(f"{OUTPUT_DIR}/js_endpoints.txt", "r") as f:
    js_count = len(f.readlines())
print(f"{GREEN}[+] {js_count} potansiyel JS uç noktası bulundu{RESET}\n")

# Adım 6: GF ile hassas veri çıkarımı
print(f"{YELLOW}[*] Hassas veriler aranıyor...{RESET}")
result = subprocess.run(f"cat {OUTPUT_DIR}/katana_results.txt {OUTPUT_DIR}/wayback_urls.txt {OUTPUT_DIR}/gau_urls.txt {OUTPUT_DIR}/js_files.txt | gf api-keys | anew {OUTPUT_DIR}/api_keys.txt", shell=True, capture_output=True)
check_error(result, "Hassas veri çıkarımı başarısız")
check_file(f"{OUTPUT_DIR}/api_keys.txt")
with open(f"{OUTPUT_DIR}/api_keys.txt", "r") as f:
    key_count = len(f.readlines())
print(f"{GREEN}[+] {key_count} potansiyel hassas veri bulundu{RESET}\n")

# Adım 7: Aktif uç noktaları doğrulama
print(f"{YELLOW}[*] Aktif uç noktalar doğrulanıyor...{RESET}")
result = subprocess.run(f"httpx -l {OUTPUT_DIR}/api_urls.txt -status-code -title -tech-detect -o {OUTPUT_DIR}/active_api_results.txt -silent -t 10", shell=True, capture_output=True)
check_error(result, "Httpx doğrulaması başarısız")
check_file(f"{OUTPUT_DIR}/active_api_results.txt")
result = subprocess.run(f"cat {OUTPUT_DIR}/active_api_results.txt | grep '200\\|301' | anew {OUTPUT_DIR}/verified_api_results.txt", shell=True, capture_output=True)
check_error(result, "Aktif uç noktalar filtrelenemedi")
check_file(f"{OUTPUT_DIR}/verified_api_results.txt")
with open(f"{OUTPUT_DIR}/verified_api_results.txt", "r") as f:
    verified_count = len(f.readlines())
print(f"{GREEN}[+] {verified_count} aktif API uç noktası doğrulandı{RESET}\n")

# Adım 8: Arjun ile gizli parametre keşfi
print(f"{YELLOW}[*] Gizli parametreler aranıyor...{RESET}")
arjun_temp = OUTPUT_DIR / "arjun_temp.txt"
arjun_results = OUTPUT_DIR / "arjun_results.txt"
if verified_count > 0:
    with open(f"{OUTPUT_DIR}/verified_api_results.txt", "r") as f:
        for line in f:
            url = line.split()[0]
            result = subprocess.run(f"arjun -u {url} -oT {arjun_temp} -q", shell=True, capture_output=True)
            if arjun_temp.exists() and arjun_temp.stat().st_size > 0:
                with open(arjun_temp, "r") as temp, open(arjun_results, "a") as out:
                    out.write(f"{url}: {temp.read().strip()}\n")
    if arjun_temp.exists():
        arjun_temp.unlink()
check_file(arjun_results)
with open(arjun_results, "r") as f:
    param_count = len(f.readlines())
print(f"{GREEN}[+] {param_count} gizli parametre bulundu{RESET}\n")

# Adım 9: Nuclei ile zafiyet tarama
print(f"{YELLOW}[*] Zafiyet taraması başlatılıyor...{RESET}")
result = subprocess.run(f"nuclei -l {OUTPUT_DIR}/verified_api_results.txt -t ~/nuclei-templates -tags api,cves -severity low,medium,high,critical -o {OUTPUT_DIR}/nuclei_results.txt -c 10 -silent", shell=True, capture_output=True)
check_error(result, "Nuclei taraması başarısız")
check_file(f"{OUTPUT_DIR}/nuclei_results.txt")
with open(f"{OUTPUT_DIR}/nuclei_results.txt", "r") as f:
    vuln_count = len(f.readlines())
print(f"{GREEN}[+] {vuln_count} zafiyet tespit edildi{RESET}\n")

# Adım 10: Dalfox ile XSS tarama
print(f"{YELLOW}[*] XSS taraması başlatılıyor...{RESET}")
result = subprocess.run(f"dalfox file {OUTPUT_DIR}/api_urls.txt -o {OUTPUT_DIR}/dalfox_results.txt -silent --no-color", shell=True, capture_output=True)
if result.returncode != 0:
    print(f"{RED}[!] Dalfox taraması başarısız, logları kontrol edin{RESET}")
    with open(LOG_FILE, "a") as f:
        f.write(f"[{datetime.datetime.now()}] Dalfox hatası: {result.stderr.decode()}\n")
check_file(f"{OUTPUT_DIR}/dalfox_results.txt")
with open(f"{OUTPUT_DIR}/dalfox_results.txt", "r") as f:
    xss_count = len(f.readlines())
print(f"{GREEN}[+] {xss_count} XSS zafiyeti tespit edildi{RESET}\n")

# JSON çıktısı oluştur
generate_json_output(OUTPUT_DIR)

# Sonuçları göster
print(f"{BLUE}========================================{RESET}")
print(f"{GREEN} TARAMA SONUÇLARI{RESET}")
print(f"{BLUE}========================================{RESET}")

# API uç noktaları (tıklanabilir)
print(f"{YELLOW}[*] Aktif API Uç Noktaları:{RESET}")
if OUTPUT_DIR.joinpath("verified_api_results.txt").exists() and OUTPUT_DIR.joinpath("verified_api_results.txt").stat().st_size > 0:
    with open(f"{OUTPUT_DIR}/verified_api_results.txt", "r") as f:
        for line in f:
            url = line.split()[0]
            status = line[line.find("["):line.find("]")+1]
            print(f"{GREEN}{url}{RESET} {status}")
else:
    print(f"{RED}Hiçbir aktif API uç noktası bulunamadı{RESET}")
print()

# JavaScript uç noktaları
print(f"{YELLOW}[*] JavaScript Dosyalarından Tespit Edilen Uç Noktalar:{RESET}")
if OUTPUT_DIR.joinpath("js_endpoints.txt").exists() and OUTPUT_DIR.joinpath("js_endpoints.txt").stat().st_size > 0:
    with open(f"{OUTPUT_DIR}/js_endpoints.txt", "r") as f:
        for line in f:
            print(f"{GREEN}{line.strip()}{RESET}")
else:
    print(f"{RED}Hiçbir JS uç noktası bulunamadı{RESET}")
print()

# Gizli parametreler
print(f"{YELLOW}[*] Tespit Edilen Gizli Parametreler:{RESET}")
if OUTPUT_DIR.joinpath("arjun_results.txt").exists() and OUTPUT_DIR.joinpath("arjun_results.txt").stat().st_size > 0:
    with open(f"{OUTPUT_DIR}/arjun_results.txt", "r") as f:
        for line in f:
            print(f"{GREEN}{line.strip()}{RESET}")
else:
    print(f"{RED}Hiçbir gizli parametre bulunamadı{RESET}")
print()

# Hassas veriler
print(f"{YELLOW}[*] Potansiyel Hassas Veriler (API Anahtarları):{RESET}")
if OUTPUT_DIR.joinpath("api_keys.txt").exists() and OUTPUT_DIR.joinpath("api_keys.txt").stat().st_size > 0:
    with open(f"{OUTPUT_DIR}/api_keys.txt", "r") as f:
        for line in f:
            print(f"{GREEN}{line.strip()}{RESET}")
else:
    print(f"{RED}Hiçbir hassas veri bulunamadı{RESET}")
print()

# Zafiyetler
print(f"{YELLOW}[*] Tespit Edilen Zafiyetler:{RESET}")
if OUTPUT_DIR.joinpath("nuclei_results.txt").exists() and OUTPUT_DIR.joinpath("nuclei_results.txt").stat().st_size > 0:
    with open(f"{OUTPUT_DIR}/nuclei_results.txt", "r") as f:
        for line in f:
            line = line.strip()
            if "[critical]" in line:
                print(f"{RED}{line}{RESET}")
            elif "[high]" in line:
                print(f"{RED}{line}{RESET}")
            elif "[medium]" in line:
                print(f"{YELLOW}{line}{RESET}")
            else:
                print(f"{GREEN}{line}{RESET}")
else:
    print(f"{RED}Hiçbir zafiyet bulunamadı{RESET}")
print()

# XSS zafiyetleri
print(f"{YELLOW}[*] Tespit Edilen XSS Zafiyetleri:{RESET}")
if OUTPUT_DIR.joinpath("dalfox_results.txt").exists() and OUTPUT_DIR.joinpath("dalfox_results.txt").stat().st_size > 0:
    with open(f"{OUTPUT_DIR}/dalfox_results.txt", "r") as f:
        for line in f:
            print(f"{RED}{line.strip()}{RESET}")
else:
    print(f"{RED}Hiçbir XSS zafiyeti bulunamadı{RESET}")
print()

# Çıktı dosyalarının konumu
print(f"{BLUE}[*] Tüm sonuçlar {OUTPUT_DIR} dizininde saklandı{RESET}")
print(f"{BLUE}[*] JSON sonuçları: {OUTPUT_DIR}/results.json{RESET}")
print(f"{BLUE}[*] Log dosyası: {LOG_FILE}{RESET}")
print(f"{BLUE}========================================{RESET}")

# Temizlik (opsiyonel)
print(f"{YELLOW}[*] Geçici dosyalar saklandı. Silmek için: rm -rf {OUTPUT_DIR}{RESET}")
with open(LOG_FILE, "a") as f:
    f.write(f"[{datetime.datetime.now()}] Tarama tamamlandı\n")
