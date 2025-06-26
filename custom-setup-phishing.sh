#!/bin/bash
set -euo pipefail

# ─── Ensure Root ───────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
export PATH=$PATH:/usr/games

# ─── Install Dependencies ──────────────────────────────────────────────
apt-get update -y
apt-get install -y curl gnupg lsb-release wget software-properties-common jq cowsay \
  -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# ─── Ensure PATH Export ────────────────────────────────────────────────
line_to_add='export PATH=$PATH:/usr/games'
grep -qxF "$line_to_add" ~/.bashrc || echo "$line_to_add" >> ~/.bashrc

# ─── Display Loading Message ───────────────────────────────────────────
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

# ─── Intro Message ─────────────────────────────────────────────────────
echo -e "\nYou took the red pill, now we will see how far the rabbit hole goes.\n"
echo "Starting data ingestion..."

# ─── SDG Setup ─────────────────────────────────────────────────────────
JAR="/root/simple-data-generator/build/libs/simple-data-generator-1.0.0-SNAPSHOT.jar"
WINDOWS_YAML="/root/simple-data-generator/secops-windows.yml"
PHISHING_YAML="/root/simple-data-generator/secops-email.yml"
LOG_FILE="/tmp/windows-sdg.log"

# ─── Run Windows Workload ──────────────────────────────────────────────
if [[ -f "$JAR" && -f "$WINDOWS_YAML" ]]; then
  echo -e "\n▶ Running Windows workload in background..."
  java -jar "$JAR" "$WINDOWS_YAML" > "$LOG_FILE" 2>&1 &
  WIN_PID=$!

  echo "⏳ Waiting for 'Workloads Started' message..."
  timeout=30  # Optional timeout in seconds
  elapsed=0

  while sleep 1; do
    if grep -q "Workloads Started" "$LOG_FILE"; then
      echo "✅ Detected 'Workloads Started'. Stopping Windows workload..."
      kill "$WIN_PID"
      wait "$WIN_PID" 2>/dev/null || true
      break
    fi

    ((elapsed++))
    if ((elapsed >= timeout)); then
      echo "⚠️ Timeout waiting for 'Workloads Started'. Stopping Windows workload..."
      kill "$WIN_PID"
      wait "$WIN_PID" 2>/dev/null || true
      break
    fi
  done
else
  echo "❌ Missing JAR or secops-windows.yml file."
  exit 1
fi

# ─── Run Phishing Workload ─────────────────────────────────────────────
if [[ -f "$PHISHING_YAML" ]]; then
  echo -e "\n▶ Starting Email Phishing workload (will run indefinitely)..."
  exec java -jar "$JAR" "$PHISHING_YAML"
else
  echo "❌ Missing secops-email.yml file."
  exit 1
fi

