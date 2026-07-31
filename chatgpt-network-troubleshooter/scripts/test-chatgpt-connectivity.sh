#!/usr/bin/env bash
set -u

ROUNDS=5
DELAY=2
PROXY=""
TEST_IPV6=0
OUTPUT_CSV="${TMPDIR:-/tmp}/chatgpt-connectivity-$(date +%Y%m%d-%H%M%S).csv"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --rounds) ROUNDS="$2"; shift 2 ;;
    --delay) DELAY="$2"; shift 2 ;;
    --proxy) PROXY="$2"; shift 2 ;;
    --ipv6) TEST_IPV6=1; shift ;;
    --output) OUTPUT_CSV="$2"; shift 2 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

case "$ROUNDS" in ''|*[!0-9]*) echo '--rounds must be an integer' >&2; exit 2;; esac
case "$DELAY" in ''|*[!0-9]*) echo '--delay must be an integer' >&2; exit 2;; esac

TARGETS=(
  'chatgpt.com|https://chatgpt.com/'
  'auth.openai.com|https://auth.openai.com/'
  'ws.chatgpt.com|https://ws.chatgpt.com/'
  'oaistatic.com|https://oaistatic.com/'
  'oaiusercontent.com|https://oaiusercontent.com/'
  'desktop.chat.openai.com|https://desktop.chat.openai.com/'
  'challenges.cloudflare.com|https://challenges.cloudflare.com/'
)

mask_proxy() {
  if [ -z "$1" ]; then
    printf 'system/default'
  else
    printf '%s' "$1" | sed -E 's#(https?|socks5h?|socks)://[^/@:]+:[^/@]+@#\1://***:***@#Ig'
  fi
}

csv_escape() {
  local value="${1//\"/\"\"}"
  printf '"%s"' "$value"
}

printf '%s\n' 'Timestamp,Round,Domain,IPVersion,Proxy,DnsOk,DnsAddresses,CurlExitCode,HttpCode,RemoteIp,NameLookupSeconds,ConnectSeconds,TlsSeconds,TotalSeconds,RawError' > "$OUTPUT_CSV"

for ((round=1; round<=ROUNDS; round++)); do
  for target in "${TARGETS[@]}"; do
    domain="${target%%|*}"
    url="${target#*|}"

    dns_ok=false
    dns_addresses=""
    if command -v getent >/dev/null 2>&1; then
      dns_addresses="$(getent ahosts "$domain" 2>/dev/null | awk '{print $1}' | sort -u | paste -sd';' -)"
    elif command -v dig >/dev/null 2>&1; then
      dns_addresses="$( { dig +short A "$domain"; dig +short AAAA "$domain"; } 2>/dev/null | sort -u | paste -sd';' -)"
    elif command -v nslookup >/dev/null 2>&1; then
      dns_addresses="$(nslookup "$domain" 2>/dev/null | awk '/^Address: /{print $2}' | paste -sd';' -)"
    fi
    [ -n "$dns_addresses" ] && dns_ok=true

    versions=(4)
    [ "$TEST_IPV6" -eq 1 ] && versions+=(6)

    for version in "${versions[@]}"; do
      args=(-sS -o /dev/null -w '%{http_code}|%{remote_ip}|%{time_namelookup}|%{time_connect}|%{time_appconnect}|%{time_total}' --connect-timeout 10 --max-time 20 --http1.1 "-$version")
      [ -n "$PROXY" ] && args+=(--proxy "$PROXY")

      set +e
      raw="$(curl "${args[@]}" "$url" 2>&1)"
      exit_code=$?
      set -e 2>/dev/null || true

      IFS='|' read -r http_code remote_ip dns_time connect_time tls_time total_time <<< "$raw"
      raw_error=""
      [ "$exit_code" -ne 0 ] && raw_error="$raw"

      {
        csv_escape "$(date -Iseconds 2>/dev/null || date)"; printf ','
        printf '%s,' "$round"
        csv_escape "$domain"; printf ','
        printf '%s,' "$version"
        csv_escape "$(mask_proxy "$PROXY")"; printf ','
        printf '%s,' "$dns_ok"
        csv_escape "$dns_addresses"; printf ','
        printf '%s,' "$exit_code"
        csv_escape "${http_code:-}"; printf ','
        csv_escape "${remote_ip:-}"; printf ','
        csv_escape "${dns_time:-}"; printf ','
        csv_escape "${connect_time:-}"; printf ','
        csv_escape "${tls_time:-}"; printf ','
        csv_escape "${total_time:-}"; printf ','
        csv_escape "$raw_error"; printf '\n'
      } >> "$OUTPUT_CSV"
    done
  done

  if [ "$round" -lt "$ROUNDS" ] && [ "$DELAY" -gt 0 ]; then
    sleep "$DELAY"
  fi
done

printf 'CSV written to: %s\n' "$OUTPUT_CSV"
printf '%s\n' 'HTTP 401/403/404 can still prove reachability. Focus on DNS, TCP, TLS, proxy, reset and timeout failures.'
