#!/bin/bash
set -euo pipefail

# Ensure root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
export PATH=$PATH:/usr/games

# Install prerequisites
apt-get update -y
apt-get install -y \
  curl gnupg lsb-release wget software-properties-common jq cowsay \
  -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# Append export if not already present
line_to_add='export PATH=$PATH:/usr/games'
grep -qxF "$line_to_add" ~/.bashrc || echo "$line_to_add" >> ~/.bashrc

# Clear the screen
clear
echo 
echo "Loading Elastic Rules, this will take a moment."
echo
echo
curl -X PUT "http://localhost:30001/api/detection_engine/rules/prepackaged" -u "sdg:changme"  --header "kbn-xsrf: true" -H "Content-Type: application/json"  -d '{}'
curl -X POST "http://localhost:30001/api/detection_engine/rules/_bulk_create" -u "sdg:changeme" --header "kbn-xsrf: true" -H "Content-Type: application/json" -d @/root/simple-data-generator/detection-rules/101-1.json
clear

sudo apt update -y
sudo apt install cowsay -y
sudo apt install cmatrix -y

# The line to add to ~/.bashrc
line_to_add='export PATH=$PATH:/usr/games'

# Check if the line already exists in .bashrc to avoid duplicates
if ! grep -Fxq "$line_to_add" ~/.bashrc; then
    # Append the line to the bottom of ~/.bashrc
    echo "$line_to_add" >> ~/.bashrc
    echo "Line added to ~/.bashrc"
else
    echo "Line already exists in ~/.bashrc"
fi

# Reload .bashrc to apply changes
source ~/.bashrc


# Clear the screen
clear

# Run cmatrix in the background
cmatrix -b -u 5 &

# Get the process ID of cmatrix to stop it later
MATRIX_PID=$!

# Wait for 2 seconds to let cmatrix start
sleep 2

# Hide cursor
tput civis

# Get terminal dimensions
rows=$(tput lines)
cols=$(tput cols)

# Center the message
message="Loading, please stand by."
message_length=${#message}
center_col=$(( (cols - message_length) / 2 ))
center_row=$(( rows / 2 ))

# Print the message in the center
tput cup $center_row $center_col
echo "$message" | cowsay

# Wait for 8 seconds with the message displayed
sleep 8

# Kill cmatrix process
kill $MATRIX_PID

# Show cursor again and clear screen
tput cnorm
clear




echo "Elastic Security says: Feed me malware!!!"
echo 
echo
echo 
echo
echo "Starting data ingestion, press CTRL + C to unplug from the Matrix."
java -jar /root/simple-data-generator/build/libs/simple-data-generator-1.0.0-SNAPSHOT.jar /root/simple-data-generator/tracks/security-101-3.yml
