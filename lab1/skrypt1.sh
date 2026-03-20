#!/bin/bash

USERNAME="karol"
HOSTNAME="archlinux"

outputBashCode() {
  echo "\`\`\`bash" >> $OUTPUT_FILE
  cat >> $OUTPUT_FILE
  echo "\`\`\`" >> $OUTPUT_FILE
}

OUTPUT_FILE="Raport1_$(date +%d.%m.%Y-%H:%M)_$HOSTNAME.md"

echo "# Raport" > $OUTPUT_FILE
echo "## Autorzy: Karol Gębski, Wojciech Malinowski" >> $OUTPUT_FILE

echo "## Komendy analzy systemu" >> $OUTPUT_FILE

echo "### Lista procesów użytkownika $USERNAME" >> $OUTPUT_FILE

ps -u $USERNAME | head -n 10 | outputBashCode

echo "### Top 10 procesów (CPU)" >> "$OUTPUT_FILE"
ps -eo user,pid,%cpu,%mem,start,time,cmd --sort=-%cpu | head -n 11 | outputBashCode

echo "### Top 10 procesów (MEM)" >> "$OUTPUT_FILE"
ps -eo user,pid,%cpu,%mem,start,time,cmd --sort=-%mem | head -n 11 | outputBashCode

echo "### Procesy uruchomione przez root" >> "$OUTPUT_FILE"
ps aux -u root | head -n 11 | outputBashCode

echo "### Drzewo procesów (Systemd i PPID=1)" >> "$OUTPUT_FILE"
{
  ps -eo pid,ppid,user,cmd --forest | head -n 10
  echo -e "\n--- Procesy z PPID=1 ---"
  ps -eo pid,ppid,user,cmd | awk '$2==1' | head -n 3
} | outputBashCode

echo "## Pakiety i Oprogramowanie" >> "$OUTPUT_FILE"

echo "### Zainstalowane aplikacje (pierwsze 15)" >> "$OUTPUT_FILE"
dpkg -l | head -n 15 | outputBashCode

echo "### Wersja OpenSSH Server" >> "$OUTPUT_FILE"
echo "Wersja: $(dpkg -l | grep openssh-server | awk '{print $3}')" >> "$OUTPUT_FILE"

echo "### Status VSFTPD" >> "$OUTPUT_FILE"
echo "Zainstalowano: $(cat /var/log/dpkg.log* | grep ' installed vsftpd' | awk '{print $1}') o godzinie $(cat /var/log/dpkg.log | grep ' installed vsftpd' | awk '{print $2}')" >> "$OUTPUT_FILE"

echo "### Pakiety zainstalowane w ostatnim tygodniu (Top 10)" >> "$OUTPUT_FILE"
grep " installed" /var/log/dpkg.log | awk -v date="$(date -d '7 days ago' '+%Y-%m-%d')" '$1 >= date {print $5}' | cut -d ":" -f 1 | head -n 10 | outputBashCode

echo "## Sieć i Porty" >> "$OUTPUT_FILE"

echo "### Unikalne porty nasłuchujące" >> "$OUTPUT_FILE"
ss -tuln | awk '{print $5}' | rev | cut -s -d ':' -f 1 | rev | sort -u | outputBashCode

echo "### Usługi nasłuchujące na 0.0.0.0" >> "$OUTPUT_FILE"
ss -tuln | grep -E '0.0.0.0:|\*:' | outputBashCode

echo "### Procesy na porcie 22 (SSH)" >> "$OUTPUT_FILE"
sudo ss -tulpn | grep :22 | outputBashCode

echo "### Skanowanie wersji (Nmap)" >> "$OUTPUT_FILE"
{
  echo "SSH (Local):"
  nmap -sV -p22 0.0.0.0 | grep 22
  echo -e "\nWikipedia (HTTP):"
  nmap -sV -p80 185.15.59.224 | grep 80
} | outputBashCode

echo "## Usługi i Systemd" >> "$OUTPUT_FILE"

echo "### Status usług (SSH i Apache2)" >> "$OUTPUT_FILE"
{
  sudo systemctl status ssh --no-pager | head -n 5
  echo -e "\n---"
  sudo systemctl status apache2 --no-pager | head -n 5
} | outputBashCode

echo "### Aktywne usługi (Top 10)" >> "$OUTPUT_FILE"
systemctl list-units --state active | head -n 11 | outputBashCode

echo "### Usługi uruchamiane przy starcie (Enabled)" >> "$OUTPUT_FILE"
sudo systemctl list-unit-files | awk '{print $1,$2}' | grep enabled | awk '{print $1}' | head -n 10 | outputBashCode

echo "## Użytkownicy i Bezpieczeństwo" >> "$OUTPUT_FILE"

echo "### Użytkownicy systemowi" >> "$OUTPUT_FILE"
awk -F':' '$2 ~ "$" {print $1}' /etc/passwd | head -n 10 | outputBashCode

echo "### Użytkownicy z dostępem do powłoki (Shell access)" >> "$OUTPUT_FILE"
awk -F: '$7 ~ /(bash|sh|zsh)$/ {print $1}' /etc/passwd | outputBashCode

echo "### Członkowie grupy sudo" >> "$OUTPUT_FILE"
getent group sudo | outputBashCode

echo "## Analiza Plików Systemowych" >> $OUTPUT_FILE
echo "### Pliki zmodyfikowane w /etc (ostatnie 7 dni)" >> $OUTPUT_FILE
sudo find /etc -type f -mtime -7 | outputBashCode

echo "### Pliki większe niż 1GB w katalogu /" >> $OUTPUT_FILE
sudo find / -type f -size +1G -maxdepth 7 2>/dev/null | outputBashCode

echo "### Lista ostatnich 50 komend wykonanych przez użytkownika root" >> $OUTPUT_FILE
sudo cat /root/.bash_history | tail -n 50 | outputBashCode

echo "## Harmonogram zadań (Cron)" >> $OUTPUT_FILE
sudo crontab -l -u root 2>&1 | outputBashCode

echo "### Logi (FTP i SSH)" >> "$OUTPUT_FILE"
{
  echo "--- VSFTPD Logs ---"
  sudo [ -f /var/log/vsftpd.log ] && sudo head -n 10 /var/log/vsftpd.log || echo "Brak logów vsftpd"
  echo -e "\n--- SSH Logs ---"
  sudo journalctl --unit ssh -n 15 --no-pager
} | outputBashCode

echo "## Informacje o Systemie Operacyjnym" >> $OUTPUT_FILE

echo "### Wersja kernela" >> $OUTPUT_FILE
uname -mrs | outputBashCode

echo "### Czas działania systemu od ostatniego uruchomienia" >> $OUTPUT_FILE
uptime -p | outputBashCode


echo "## Parametry Sprzętowe" >> $OUTPUT_FILE

echo "### Pamięć RAM" >> $OUTPUT_FILE
free -h | outputBashCode

echo "### Procesor (vCPU i Taktowanie)" >> $OUTPUT_FILE
lscpu | grep -E '^CPU:|Model name|min MHz|max MHz' | outputBashCode

echo "### Rozmiar dysków twardych" >> $OUTPUT_FILE
lsblk | grep "disk" | outputBashCode


echo "## Konfiguracja Sieciowa" >> $OUTPUT_FILE

echo "### Adresy IP (IPv4/IPv6)" >> $OUTPUT_FILE
ip addr  | outputBashCode

echo "### Serwery DNS" >> $OUTPUT_FILE
if [ -f /etc/resolv.conf ]; then
    grep "nameserver" /etc/resolv.conf | outputBashCode
else
    resolvectl dns | outputBashCode
fi

echo "### Tablica sąsiedztwa (ARP - IP na MAC)" >> $OUTPUT_FILE
ip neighbor show | outputBashCode

echo "### Tablica routingu" >> $OUTPUT_FILE
ip route show | outputBashCode

echo "### Brama domyślna" >> $OUTPUT_FILE
ip route | grep default | outputBashCode

echo "### Interfejsy sieciowe w systemie" >> $OUTPUT_FILE
ip link show | outputBashCode

echo "## Reguły zapory sieciowej (iptables)" >> $OUTPUT_FILE
sudo iptables -L | outputBashCode

echo "### Status AppArmor" >> "$OUTPUT_FILE"
sudo apparmor_status | head -n 16 | outputBashCode