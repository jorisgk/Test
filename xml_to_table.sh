#!/bin/bash
# xml_to_table.sh - parse simple XML user blocks using grep/sed/awk only
# Usage: ./xml_to_table.sh users.xml

FILE="${1:-/dev/stdin}"
if [[ ! -e "$FILE" ]]; then
  echo "Bestand niet gevonden: $FILE" > /dev/null
  exit 1
fi

# Print header
printf "%-20s | %-20s | %-25s | %-10s | %-6s\n" "USER_GROUPS" "DN" "FULL_NAME" "EMAIL" "DYN_NR"
printf "%s\n" "----------------------+----------------------+---------------------------+------------+--------"