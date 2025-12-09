#!/bin/bash

inputfile="uds.xml"

# Stap 1: Bepaal alle metadata-kolommen dynamisch
columns=("dn")
mapfile -t meta_fields < <(awk -F'"' '/<metadata name=/ {print $2}' "$inputfile" | sort -u)
columns+=("${meta_fields[@]}")

# Print header
for col in "${columns[@]}"; do
    printf "%-25s | " "$col"
done
echo
for ((i=0; i<${#columns[@]}; i++)); do
    printf "%-25s+" "-------------------------"
done
echo

# Stap 2: Verwerk elk <user> blok met awk (hele script binnen quotes)
awk -v colcount="${#columns[@]}" -v colnames_str="$(IFS="|"; echo "${columns[*]}")"
BEGIN {
    # Zet kolommen in een array
    n = split(colnames_str, colnames, "|")
}
# Start van user
/<user / {
    for(i=1;i<=n;i++) user[colnames[i]]="";
    match($0, /dn="[^"]+\"/, a);
    if(a[0]!="") user["dn"]=substr(a[0],5,length(a[0])-5);
}
/<metadata name=/ {
    match($0, /<metadata name="([^"]+)">([^<]*)<\/metadata>/, m);
    if(m[1]!="") user[m[1]]=m[2];
}
/<\/user>/ {
    for(i=1;i<=n;i++){
        printf "%-25s | ", user[colnames[i]];
    }
    print "";
}
"$inputfile"

