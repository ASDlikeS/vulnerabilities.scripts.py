#!/bin/bash

DEFAULT_RECORD_TYPE="ANY"
OUTPUT_FILE="dns_report.txt"

show_help() {
  echo "    _    ____  ____    ____  _   _ ____  "
  echo "   / \  / ___||  _ \  |  _ \| \ | / ___| "
  echo "  / _ \ \___ \| | | | | | | |  \| \___ \ "
  echo " / ___ \ ___) | |_| | | |_| | |\  |___) |"
  echo "/_/   \_\____/|____/  |____/|_| \_|____/ "
  echo ""
  echo ""
  echo " ____  _____ ____ ___  ____  ____  ____  "
  echo "|  _ \| ____/ ___/ _ \|  _ \|  _ \/ ___| "
  echo "| |_) |  _|| |  | | | | |_) | | | \___ \ "
  echo "|  _ <| |__| |__| |_| |  _ <| |_| |___) |"
  echo "|_| \_\_____\____\___/|_| \_\____/|____/ "
  echo ""
  echo "Usage: $0 [-t RECORD_TYPE] [-f FILE] [DOMAINS...]"
  echo "Examples:"
  echo "  $0 -t MX example.com"
  echo "  $0 -f domains.txt"
  echo "  $0 -t TXT -f domains.txt"
  echo ""
  echo "Options:"
  echo "  -t  TYPE DNS RECORD (A, MX, TXT and other..., BY DEFAULT: ANY)"
  echo "  -f  FILE WITH DOMAINS, SUBDOMAINS (string by string ONLY)"
  exit 0
}

check_dependencies() {
  if ! command -v dig &> /dev/null; then 
    echo "ERROR: dig doesn't exist in environment. Install package dnsutils/bind-utils" >&2
    exit 1
  fi
}

check_dns() {
  local domain=$1 
  echo "[+] Checking $domain ($record_type)" | tee -a "$OUTPUT_FILE"
  local response
  response=$(dig +noall +answer +time=5 +tries=2 "$domain" "$record_type")
  if [ -n "$response" ]; then
    printf "%s\n---Records found---\n" "$response" | tee -a "$OUTPUT_FILE"
    echo "----------------------------------------" | tee -a "$OUTPUT_FILE"
  else
    echo "No records found for $domain ($record_type)" >&2
  fi	
}

check_dependencies

record_type="$DEFAULT_RECORD_TYPE"
domains=()

while getopts "t:f:h" opt; do
  case $opt in
    t) record_type="$OPTARG" ;;
    f) input_file="$OPTARG" ;;
    h) show_help ;;
    *) echo "Unknown option. Use -h for get a help message" >&2; exit 1 ;;
  esac
done
shift $((OPTIND-1))

valid_records=("A" "AAAA" "MX" "TXT" "CNAME" "NS" "SOA" "ANY")
if [[ ! " ${valid_records[*]} " =~ " $record_type " ]]; then
  echo "ERROR: Unknown record's type '$record_type'" >&2
  echo "Available types: ${valid_records[*]}" >&2
  exit 1
fi

if [ -n "$input_file" ]; then
  if [ ! -f "$input_file" ]; then
    echo "ERROR: File '$input_file' doesn't exist" >&2
    exit 1
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    line_clean=$(echo "$line" | sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    [ -n "$line_clean" ] && domains+=("$line_clean")
  done < "$input_file"
fi

domains+=("$@")

# Проверка наличия доменов
if [ ${#domains[@]} -eq 0 ]; then
  echo "ERROR: Didn't choose any domains for checking" >&2
  exit 1
fi

: > "$OUTPUT_FILE"

# Обработка доменов
for domain in "${domains[@]}"; do
  check_dns "$domain"
done

echo "-------------"Report saved in: $OUTPUT_FILE-------------"
