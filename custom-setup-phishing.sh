#!/bin/bash
set -euo pipefail

# Ensure root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
export PATH=$PATH:/usr/games

# Install dependencies (only once)
apt-get update -y
apt-get install -y curl gnupg lsb-release wget software-properties-common jq cowsay \
  -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# Ensure PATH export in .bashrc
line_to_add='export PATH=$PATH:/usr/games'
grep -qxF "$line_to_add" ~/.bashrc || echo "$line_to_add" >> ~/.bashrc

# Loading message
clear
tput civis || true
rows=$(tput lines)
cols=$(tput cols)
message="Loading, please stand by."
center_col=$(( (cols - ${#message}) / 2 ))
center_row=$(( rows / 2 ))
tput cup $center_row $center_col || true
echo "$message" | cowsay
sleep 3
tput cnorm || true
clear

# Intro message
echo -e "\nYou took the red pill, now we will see how far the rabbit hole goes.\n"
echo "Starting data ingestion, press CTRL + C to unplug from the Matrix."

# Run Windows workload, detect readiness, then continue to phishing
JAR="/root/simple-data-generator/build/libs/simple-data-generator-1.0.0-SNAPSHOT.jar"
WINDOWS_YAML="/root/simple-data-generator/secops-windows.yml"
PHISHING_YAML="/root/simple-data-generator/secops-email.yml"
LOG_FILE="/tmp/windows-sdg.log"

if [[ -f "$JAR" && -f "$WINDOWS_YAML" ]]; then
  echo -e "\n▶ Starting Windows workload..."
  java -jar "$JAR" "$WINDOWS_YAML" > "$LOG_FILE" 2>&1 &
  WIN_PID=$!

  echo "⏳ Waiting for 'Workloads Started' message..."

  while sleep 1; do
    if grep -q "Workloads Started" "$LOG_FILE"; then
      echo "✅ 'Workloads Started' detected. Stopping Windows workload..."
      kill $WIN_PID
      wait $WIN_PID 2>/dev/null || true
      break
    fi
  done
else
  echo "❌ Missing JAR or YAML for Windows workload."
  exit 1
fi

# Run phishing workload in foreground (leave it running)
if [[ -f "$PHISHING_YAML" ]]; then
  echo -e "\n▶ Starting Email Phishing workload (will run indefinitely)..."
  exec java -jar "$JAR" "$PHISHING_YAML"
else
  echo "❌ Missing $PHISHING_YAML"
  exit 1
fi
