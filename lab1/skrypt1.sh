#!/bin/bash

USERNAME="karol"
HOSTNAME="archlinux"

OUTPUT_FILE="Raport1_$(date +%d.%m.%Y-%H:%M)_$HOSTNAME.md"

echo "# Raport" > $OUTPUT_FILE
echo "## Autorzy: Karol Gębski, Wojciech Malinowski" >> $OUTPUT_FILE

echo "## Komendy analzy systemu" >> $OUTPUT_FILE

echo "### Lista procesów użytkownika $USERNAME" >> $OUTPUT_FILE

echo "\`\`\`bash" >> $OUTPUT_FILE

ps -u $USERNAME | head -n 10 >> $OUTPUT_FILE

echo "\`\`\`" >> $OUTPUT_FILE