#!/bin/bash

# Define color codes for output
RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[32m'
CYAN='\033[36m'
YELLOW='\033[33m'
MAGENTA='\033[35m'
RED='\033[31m'
BLUE='\033[34m'

# Function to print section headers and separators
print_section() {
  echo ""
  echo -e "-------------------------------------------------------"
  echo ""
  echo -e "${CYAN}#${RESET} $1"
  echo -e "---------------------------"
}

# Check if the URL and output directory are provided
if [ -z "$1" ] || [ -z "$2" ]; then
  echo -e "${RED}${BOLD}Error:${RESET} Usage: $0 <audio_url> <output_directory>"
  exit 1
fi

# Get the URL and target folder
audio_url="$1"
output_dir="$2"

# Extract filename from URL
filename=$(basename "$audio_url")
basename="${filename%.*}"

# Ensure the output directory exists
mkdir -p "$output_dir"

# Step 1: Download the MP3 file using aria2c
print_section "Downloading"
echo ""
echo -e "${CYAN}$audio_url${RESET}"
echo ""

# Download the file to the specified folder
aria2c --file-allocation=none -c -s 16 -x 16 -k 1M -j 1 -d "$output_dir" "$audio_url" > /dev/null 2>&1

# Check if the file was successfully downloaded
if [ ! -f "$output_dir/$filename" ]; then
  echo -e "${RED}${BOLD}Error:${RESET} File download failed."
  exit 1
fi

echo -e "${GREEN}- Download complete:${RESET} $output_dir/$filename"

# Sleep for 1 second to ensure the download has fully completed
sleep 1

# Step 2: Generate the waveform using audiowaveform
print_section "Generating Waveform"
echo ""

# Simulated waveform generation progress
echo -e "${CYAN}၊၊||၊|။||||။‌‌‌|၊၊၊||၊။‌‌‌‌‌၊||၊။‌‌‌‌‌||||။|၊||၊၊${RESET}"
echo ""

# Generate the waveform
audiowaveform -i "$output_dir/$filename" -o "$output_dir/$basename.json" --pixels-per-second 20 --bits 8 2>/dev/null

# Check if the waveform was successfully generated
if [ ! -f "$output_dir/$basename.json" ]; then
  echo -e "${RED}${BOLD}Error:${RESET} Waveform generation failed."
  exit 1
fi

# Sleep for 1 second to ensure waveform generation completes before normalization
sleep 1

# Step 3: Normalize the waveform JSON using Python script

# Normalize the waveform JSON
python normalize.py "$output_dir/$basename.json" 2>/dev/null

# Check if the normalization was successful
if [ $? -ne 0 ]; then
  echo -e "${RED}${BOLD}Error:${RESET} Normalization failed."
  exit 1
fi

echo -e "${GREEN}- Waveform generation complete:${RESET} $output_dir/$basename.json"

# Sleep for 1 second to make sure everything finishes before exiting
sleep 1

echo ""
echo -e "---------------------------------------------------------------------------"
