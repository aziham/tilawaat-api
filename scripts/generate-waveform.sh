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

# Default audio file extensions to look for
DEFAULT_EXTENSIONS=("mp3" "wav" "ogg" "flac" "aac" "m4a")

# Function to print section headers and separators
print_section() {
  echo -e "-------------------------------------------------------"
  echo ""
  echo -e "${CYAN}#${RESET} $1"
  echo -e "---------------------------"
}

# Root directory to search for audio files
DATA_DIR="endpoint/recitations/"

# Check if custom data directory is provided
if [ -n "$1" ]; then
  DATA_DIR="$1"
fi

print_section "Scanning for Audio Files"
echo -e "Looking in: ${CYAN}$DATA_DIR${RESET}"
echo ""

# Counter for processed files
processed=0
skipped=0
failed=0

# Create a pattern for find command to match our extensions
pattern=""
for ext in "${DEFAULT_EXTENSIONS[@]}"; do
  pattern="$pattern -o -name \"*.$ext\""
done
# Remove the initial "-o " from the pattern
pattern="${pattern:4}"

# Find all audio files recursively
# We're using eval here because we need to expand the pattern for find
audio_files=$(eval "find \"$DATA_DIR\" -type f \( $pattern \)")

# Check if any audio files were found
if [ -z "$audio_files" ]; then
  echo -e "${YELLOW}No audio files found in $DATA_DIR${RESET}"
  exit 0
fi

# Count total files
total_files=$(echo "$audio_files" | wc -l)
echo -e "Found ${CYAN}$total_files${RESET} audio files"
echo ""

# Process each audio file
echo "$audio_files" | while read -r audio_file; do
  # Extract filename without extension
  filename=$(basename "$audio_file")
  dirname=$(dirname "$audio_file")
  basename="${filename%.*}"
  
  # Output JSON file path
  json_file="$dirname/$basename.json"
  
  # Check if JSON already exists and skip if it does
  if [ -f "$json_file" ]; then
    echo -e "${YELLOW}Skipping (already exists):${RESET} $json_file"
    ((skipped++))
    continue
  fi
  
  echo -e "${MAGENTA}Processing:${RESET} $audio_file"
  
  # Step 2: Generate the waveform using audiowaveform
  echo ""
  
  # Simulated waveform generation progress
  echo -e "${CYAN}၊၊||၊|။||||။‌‌‌|၊၊၊||၊။‌‌‌‌‌၊||၊။‌‌‌‌‌||||။|၊||၊၊${RESET}"
  echo ""
  
  # Generate the waveform
  audiowaveform -i "$audio_file" -o "$json_file" --pixels-per-second 20 --bits 8 2>/dev/null
  
  # Check if the waveform was successfully generated
  if [ ! -f "$json_file" ]; then
    echo -e "${RED}${BOLD}Error:${RESET} Waveform generation failed for $filename"
    ((failed++))
    continue
  fi
  
  # Step 3: Normalize the waveform JSON using Python script
  # Normalize the waveform JSON
  python "$(dirname "$0")/normalize.py" "$json_file" 2>/dev/null
  
  # Check if the normalization was successful
  if [ $? -ne 0 ]; then
    echo -e "${RED}${BOLD}Error:${RESET} Normalization failed for $filename"
    ((failed++))
    continue
  fi
  
  echo -e "${GREEN}- Waveform generation complete:${RESET} $json_file"
  ((processed++))
  echo ""
  # Separator between files
  echo -e "-------------------------------------------------------"
  echo ""
done

# Print summary
print_section "Summary"
echo -e "Total files found:    ${CYAN}$total_files${RESET}"
echo -e "Successfully processed: ${GREEN}$processed${RESET}"
echo -e "Skipped (already exist): ${YELLOW}$skipped${RESET}"
echo -e "Failed:                 ${RED}$failed${RESET}"
echo ""
echo -e "---------------------------------------------------------------------------"
