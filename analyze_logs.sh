#!/usr/bin/env bash

set -euo pipefail

log_file="access.log"

# Повторяющийся набор из 10 адресов:
# первый встречается 4 раза, второй — 3, третий — 2, четвёртый — 1.
ips=(
    "192.168.1.10"
    "192.168.1.10"
    "192.168.1.10"
    "192.168.1.10"
    "10.0.0.5"
    "10.0.0.5"
    "10.0.0.5"
    "172.16.0.3"
    "172.16.0.3"
    "192.168.1.20"
)

statuses=(200 200 200 201 200 301 400 401 500 503)
methods=("GET" "POST")
paths=("/api/users" "/api/login")

# Каждый запуск заново создаёт тестовый лог.
{
    for ((i = 0; i < 300; i++)); do
        index=$((i % 10))
        request_index=$((i % 2))

        printf '%s - - [15/Aug/2026:10:%02d:%02d] "%s %s HTTP/1.1" %s\n' \
            "${ips[$index]}" \
            "$((i / 60))" \
            "$((i % 60))" \
            "${methods[$request_index]}" \
            "${paths[$request_index]}" \
            "${statuses[$index]}"
    done
} > "$log_file"

echo "Создан тестовый файл: $log_file"

echo
echo "Общее количество запросов:"
awk 'END { print NR }' "$log_file"

echo
echo "Топ-3 IP-адреса по количеству запросов:"

# Регулярное выражение для IPv4: каждый октет от 0 до 255.
octet='(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])'
ip_regex="^(${octet}\.){3}${octet}[[:space:]]"

grep -Eo "$ip_regex" "$log_file" \
    | awk '{ print $1 }' \
    | sort \
    | uniq -c \
    | sort -k1,1nr -k2,2 \
    | head -n 3 \
    | awk '{ printf "%s — %d запросов\n", $2, $1 }'

echo
echo "Количество запросов с кодами 4xx и 5xx:"

awk '
    $NF ~ /^4[0-9][0-9]$/ { errors4++ }
    $NF ~ /^5[0-9][0-9]$/ { errors5++ }
    END {
        printf "4xx: %d\n", errors4
        printf "5xx: %d\n", errors5
        printf "Всего 4xx и 5xx: %d\n", errors4 + errors5
    }
' "$log_file"
