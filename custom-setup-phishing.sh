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

# Run both workloads
JAR="/root/simple-data-generator/build/libs/simple-data-generator-1.0.0-SNAPSHOT.jar"
WINDOWS_YAML="/root/simple-data-generator/secops-windows.yml"
PHISHING_YAML="/root/simple-data-generator/secops-email.yml"

if [[ -f "$JAR" ]]; then
  if [[ -f "$WINDOWS_YAML" ]]; then
    echo -e "\n▶ Running Windows workload..."
    java -jar "$JAR" "$WINDOWS_YAML"
  else
    echo "❌ Missing $WINDOWS_YAML"
  fi

  if [[ -f "$PHISHING_YAML" ]]; then
    echo -e "\n▶ Running Email Phishing workload..."
    java -jar "$JAR" "$PHISHING_YAML"
  else
    echo "❌ Missing $PHISHING_YAML"
  fi
else
  echo "❌ SDG JAR file not found: $JAR"
  exit 1
fi

