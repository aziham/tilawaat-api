#!/bin/bash

# Check if the URL is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <reciter_base_url>"
  exit 1
fi

# Extract reciter name from the URL
base_url="$1"
reciter_folder=$(echo "$base_url" | sed -E 's|.*/quran/([^/]+)/?$|\1|')

# Define paths
output_root="$reciter_folder/waveforms"

# Create necessary directories
mkdir -p "$output_root"

# Loop through Surah numbers from 001 to 114
for i in {1..114}; do
  surah=$(printf "%03d" "$i")  # Ensures 001, 002, ..., 114
  surah_folder="$output_root/$surah"

  # Create the folder for the Surah
  mkdir -p "$surah_folder"

  # Construct the MP3 URL
  audio_url="${base_url}${surah}.mp3"

  # Call generate-waveform.sh with the correct output path
  ./generate-waveform.sh "$audio_url" "$surah_folder"
done

echo "All waveforms generated successfully!"
