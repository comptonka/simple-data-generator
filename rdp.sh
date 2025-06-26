#!/bin/bash
set -euo pipefail

# Ensure root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
export PATH=$PATH:/usr/games

# Install dependencies
apt-get update -y
apt-get install -y curl gnupg lsb-release wget software-properties-common jq cowsay \
  -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# Display loading message
clear
tput civis || true
rows=$(tput lines)
cols=$(tput cols)
message="Loading, please stand by."
center_col=$(( (cols - ${#message}) / 2 ))
center_row=$(( rows / 2 ))
tput cup $center_row $center_col || true
echo "$message" | cowsay

# Brief pause
sleep 3
tput cnorm || true
clear

# Display message and begin ingestion
echo -e "\nYou took the red pill, now we will see how far the rabbit hole goes.\n"
echo "Starting data ingestion, press CTRL + C to unplug from the Matrix."

# Run the SDG jar
JAR="/root/simple-data-generator/build/libs/simple-data-generator-1.0.0-SNAPSHOT.jar"
YAML="/root/simple-data-generator/secops-windows.yml"

if [[ -f "$JAR" && -f "$YAML" ]]; then
  exec java -jar "$JAR" "$YAML"
else
  echo "❌ SDG JAR or YAML file not found. Check paths:"
  echo "JAR:  $JAR"
  echo "YAML: $YAML"
  exit 1
fi
