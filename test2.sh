#!/bin/bash

input="uds.xml"
output="usercheck.csv"

# Schrijf eerst de kopregel
echo "DN,ADMIN,Full Name,Role1,Role2,Role3,Role4" > "$output"

awk '
/<user / {
    # reset variabelen voor elke user
    delete roles
    role_count = 0

    # admin en dn
    if (match($0, /admin="([^"]+)"/, a)) admin = a[1]
    if (match($0, /dn="([^"]+)"/, b)) dn = b[1]

    # group
    if (match($0, /group="([^"]+)"/, c)) {
        group = c[1]
        n = split(group, arr, ",")
        for (i=1; i<=n; i++) {
            if (match(arr[i], /\|USR\|[^|]+/, u)) {
                role_count++
                roles[role_count] = u[0]
                sub(/\|USR\|/, "", roles[role_count])
            }
        }
    }

    # reset fullName
    fullName = ""
}

/<metadata name="Full Name">/ {
    # haal Full Name op, incl. spaties
    if (match($0, /<metadata name="Full Name">([^<]+)<\/metadata>/, d))
        fullName = d[1]
}

/<\/user>/ {
    # DN mag niet beginnen met : en niet met __
    if (substr(dn,1,1) != ":" && substr(dn,1,2) != "__") {
        # print DN, admin, Full Name en rollen (max 4) in CSV
        printf "%s,%s,%s", dn, admin, fullName
        for (i=1; i<=4; i++) {
            if (i <= role_count)
                printf ",%s", roles[i]
            else
                printf ","
        }
        printf "\n"
    }
}
' "$input" | sort -t, -k1,1n >> "$output"
