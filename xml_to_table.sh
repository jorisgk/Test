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
# Stream parse: combine lines within a <user ...>...</user> block, then extract fields with sed/awk
awk '
  BEGIN { RS="</user>"; ORS=""; }
  /<user[[:space:]]/ {
    block = $0 "</user>";              # compleet user-block
    # Extract user group attribute (user group string between quotes after user group=)
    ug=""; dn=""; fullname=""; email=""; dyn="";
    # user groups attribute (user group="<value>")
    if (match(block, /<user[^>]*user group="[^\"]*"/)) {
      # extract between first quote after user group=
      tmp = substr(block, RSTART, RLENGTH)
      sub(/.*user group="/, "", tmp)
      sub(/".*/, "", tmp)
      ug = tmp
    } else if (match(block, /<user[^>]*user_group="/)) { # fallback underscore name
      tmp = substr(block, RSTART, RLENGTH)
      sub(/.*user_group="/, "", tmp)
      sub(/".*/, "", tmp)
      ug = tmp
    }
    # dn attribute
    if (match(block, /dn="[^\"]*"/)) {
      tmp = substr(block, RSTART, RLENGTH)
      sub(/dn="/, "", tmp); sub(/".*/, "", tmp)
      dn = tmp
    }
    # metadata fields: use regexp to capture <metadata name="...">value</metadata>
    # iterate over matches
    meta_block = block
    while (match(meta_block, /<metadata[[:space:]]+name="[^"]*"[^>]*>([^<]*)<\/metadata>/)) {
      full = substr(meta_block, RSTART, RLENGTH)
      # extract name
      name=""
      if (match(full, /name="[^"]*"/)) {
        name = substr(full, RSTART, RLENGTH)
        sub(/name="/, "", name); sub(/".*/, "", name)
      }
      # extract value between tags
      val = ""
      if (match(full, />[^<]*</)) {
        val = substr(full, RSTART+1, RLENGTH-2)
      }
      # normalize whitespace
      gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", val)
      # assign to variables we care about (case-insensitive compare)
      lname = tolower(name)
      if (lname == "full name") fullname = val
      else if (lname == "e-mail address") email = val
      else if (lname == "dynamicusernumber" || lname == "dynamic user number") dyn = val
      # remove up to end of this match and continue
      meta_block = substr(meta_block, RSTART+RLENGTH)
    }
    # fallback empty values to "-"
    if (ug=="") ug="-"
    if (dn=="") dn="-"
    if (fullname=="") fullname="-"
    if (email=="") email="-"
    if (dyn=="") dyn="-"
    # print formatted line
    printf "%-20s | %-20s | %-25s | %-10s | %-6s\n", ug, dn, fullname, email, dyn
  }
' "$FILE"