#!/bin/bash

PING_COUNT=4           
LOG_FILE="/var/log/ping_telegram.log" 
SLEEP_INTERVAL=1800    

log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $message" >> "$LOG_FILE"
}

send_telegram_message() {
    local message="$1"
    local token="$2"
    local chat_id="$3"
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d text="$message" > /dev/null
}

validate_ip() {
    local ip="$1"
    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

echo "Enter IP address or path to file with IP addresses (e.g., ip_list.txt):"
read INPUT
echo "Enter your Telegram API token:"
read TELEGRAM_TOKEN
echo "Enter your Telegram Chat ID:"
read CHAT_ID

if [[ -z "$INPUT" || -z "$TELEGRAM_TOKEN" || -z "$CHAT_ID" ]]; then
    echo "Error: All fields are required!"
    log_message "Error: Missing input parameters"
    exit 1
fi

if [[ -f "$INPUT" ]]; then
    IP_LIST="$INPUT"
    log_message "Using IP list file: $IP_LIST"
elif validate_ip "$INPUT"; then
    IP_LIST=$(mktemp)
    echo "$INPUT" > "$IP_LIST"
    log_message "Using single IP: $INPUT"
else
    echo "Error: Invalid IP address or file does not exist!"
    log_message "Error: Invalid IP or file: $INPUT"
    exit 1
fi

if [[ ! "$TELEGRAM_TOKEN" =~ ^[0-9]+:[A-Za-z0-9_-]+$ ]]; then
    echo "Error: Invalid Telegram API token format!"
    log_message "Error: Invalid Telegram token format"
    exit 1
fi

if [[ ! "$CHAT_ID" =~ ^-?[0-9]+$ ]]; then
    echo "Error: Invalid Chat ID format!"
    log_message "Error: Invalid Chat ID format"
    exit 1
fi

while true; do
    while IFS= read -r HOST; do
        [[ -z "$HOST" ]] && continue
        if ! validate_ip "$HOST"; then
            log_message "Invalid IP in list: $HOST"
            continue
        fi
        if ping -c "$PING_COUNT" "$HOST" > /dev/null 2>&1; then
            MESSAGE="✅ Host $HOST is ALIVE NOW!"
            send_telegram_message "$MESSAGE" "$TELEGRAM_TOKEN" "$CHAT_ID"
            log_message "$MESSAGE"
        else
            log_message "❌ Host $HOST is dead..."
        fi
    done < "$IP_LIST"

    log_message "Waiting for $SLEEP_INTERVAL seconds..."
    sleep "$SLEEP_INTERVAL"
done