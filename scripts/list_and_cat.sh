#!/bin/bash

# Bash script to display the contents of all files in a specified subdirectory
# It prints the file name before outputting its contents.
#
# Usage: ./list_and_cat.sh [directory]
# If no directory is provided, the current directory is used.

TARGET_DIR="${1:-.}"

# Check if the target directory exists
if [ ! -d "$TARGET_DIR" ]; then
  echo "Directory '$TARGET_DIR' does not exist."
  exit 1
fi

# Find all files in the target directory and its subdirectories
find "$TARGET_DIR" -type f | while read -r file; do
    # Print the file name
    echo "----- $file -----"
    # Display the file contents
    cat "$file"
    echo ""
done

