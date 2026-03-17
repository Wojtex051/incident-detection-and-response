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


echo "## Analiza Plików Systemowych" >> $OUTPUT_FILE
echo "### Pliki zmodyfikowane w /etc (ostatnie 7 dni)" >> $OUTPUT_FILE
sudo find /etc -type f -mtime -7 | outputBashCode

echo "### Pliki większe niż 1GB w katalogu /" >> $OUTPUT_FILE
sudo find / -type f -size +1G -maxdepth 7 2>/dev/null | outputBashCode


echo "### Lista ostatnich 50 komend wykonanych przez użytkownika root" >> $OUTPUT_FILE
sudo cat /root/.bash_history | tail -n 50 | outputBashCode


echo "## Harmonogram zadań (Cron)" >> $OUTPUT_FILE
sudo crontab -l -u root 2>&1 | outputBashCode

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

echo "## Status AppArmor / SELinux" >> $OUTPUT_FILE

{
    echo "--- Sprawdzanie AppArmor ---"
    if command -v aa-status >/dev/null 2>&1; then
        sudo aa-status
    else
        echo "AppArmor nie jest zainstalowany lub brak narzędzi aa-status."
    fi

    echo -e "\n--- Sprawdzanie SELinux ---"
    if command -v getenforce >/dev/null 2>&1; then
        getenforce
    else
        echo "SELinux nie jest zainstalowany lub aktywny."
    fi
} | outputBashCode