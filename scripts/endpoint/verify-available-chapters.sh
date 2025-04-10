#!/bin/bash

# Output file
OUTPUT_FILE="missing_chapters.log"
> "$OUTPUT_FILE" # Clear previous content

# Color codes
RED='\033[0;31m'
NC='\033[0m' # No Color

# Read JSON file
data=$(cat recitations.json)

# Loop through each reciter
echo "$data" | jq -c '.[]' | while read -r reciter; do
  id=$(echo "$reciter" | jq -r '.id')
  server=$(echo "$reciter" | jq -r '.server')

  echo -e "Checking reciter ${RED}$id${NC} ($server)..."

  # Get available chapters
  chapters=$(echo "$reciter" | jq -r '.available_chapters[]')

  missing_chapters=()

  for chapter in $chapters; do
    # Format chapter number with leading zeros
    chapter_str=$(printf "%03d" "$chapter")
    url="${server}${chapter_str}.mp3"

    # Check if URL exists (no delay)
    if ! curl --output /dev/null --silent --head --fail "$url"; then
      missing_chapters+=("$chapter")
    fi
  done

  if [ ${#missing_chapters[@]} -gt 0 ]; then
    # Print missing chapters in red
    echo -e "${RED}  Missing chapters: ${missing_chapters[*]}${NC}"

    # Save to file (format: "ID: [missing chapters]")
    echo "$id: [${missing_chapters[*]}]" >> "$OUTPUT_FILE"
  fi
done

echo -e "\nResults saved to ${RED}$OUTPUT_FILE${NC}"
