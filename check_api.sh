#!/usr/bin/env bash

# Проверяем количество аргументов.
if [[ $# -ne 1 ]]; then
    echo "Использование: $0 <http://URL или https://URL>" >&2
    exit 1
fi

url="$1"

# Разрешаем только HTTP и HTTPS.
case "$url" in
    http://*|https://*)
        ;;
    *)
        echo "Ошибка: URL должен начинаться с http:// или https://" >&2
        exit 1
        ;;
esac

# Сохраняем HTTP-код, не выводя тело ответа.
if ! http_code=$(curl \
    --silent \
    --show-error \
    --output /dev/null \
    --write-out '%{http_code}' \
    --connect-timeout 5 \
    --max-time 20 \
    "$url"); then
    echo "API недоступен, код ответа: ${http_code:-000}"
    echo "Не удалось выполнить HTTP-запрос." >&2
    exit 1
fi

if [[ "$http_code" == "200" ]]; then
    echo "API доступен"
    exit 0
else
    echo "API недоступен, код ответа: $http_code"
    exit 1
fi
