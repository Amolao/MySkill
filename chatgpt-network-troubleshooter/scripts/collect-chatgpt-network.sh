#!/usr/bin/env bash
set -u

OUTPUT_DIR="${1:-${TMPDIR:-/tmp}/chatgpt-network-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$OUTPUT_DIR"

SUMMARY="$OUTPUT_DIR/summary.txt"
NETWORK="$OUTPUT_DIR/proxy-routing-dns.txt"
PROCESSES="$OUTPUT_DIR/processes-and-listeners.txt"
REACHABILITY="$OUTPUT_DIR/openai-reachability.txt"

section() {
  printf '\n===== %s =====\n' "$2" >> "$1"
}

capture() {
  local file="$1" title="$2"
  shift 2
  section "$file" "$title"
  "$@" >> "$file" 2>&1 || printf 'Command failed with exit code %s\n' "$?" >> "$file"
}

mask_proxy_env() {
  env | grep -Ei '^(http|https|all|no)_proxy=' | \
    sed -E 's#(https?|socks5h?|socks)://[^/@:]+:[^/@]+@#\1://***:***@#Ig' || true
}

{
  printf 'Collected: %s\n' "$(date -Iseconds 2>/dev/null || date)"
  printf 'Host: %s\n' "$(hostname)"
  printf 'User: %s\n' "${USER:-unknown}"
  printf 'Output: %s\n' "$OUTPUT_DIR"
} > "$SUMMARY"

capture "$SUMMARY" 'Operating system' uname -a
capture "$SUMMARY" 'System time' date
section "$NETWORK" 'Proxy environment variables (credentials masked)'
mask_proxy_env >> "$NETWORK"

if command -v scutil >/dev/null 2>&1; then
  capture "$NETWORK" 'macOS proxy settings' scutil --proxy
  capture "$NETWORK" 'macOS DNS' scutil --dns
fi

if command -v networksetup >/dev/null 2>&1; then
  capture "$NETWORK" 'macOS network services' networksetup -listallnetworkservices
fi

if command -v ip >/dev/null 2>&1; then
  capture "$NETWORK" 'IPv4 routes' ip route
  capture "$NETWORK" 'IPv6 routes' ip -6 route
  capture "$NETWORK" 'Addresses' ip address
elif command -v route >/dev/null 2>&1; then
  capture "$NETWORK" 'Default route' route -n get default
fi

if command -v resolvectl >/dev/null 2>&1; then
  capture "$NETWORK" 'DNS configuration' resolvectl status
elif [ -f /etc/resolv.conf ]; then
  capture "$NETWORK" 'resolv.conf' cat /etc/resolv.conf
fi

if command -v lsof >/dev/null 2>&1; then
  capture "$PROCESSES" 'Listening TCP sockets' lsof -nP -iTCP -sTCP:LISTEN
elif command -v ss >/dev/null 2>&1; then
  capture "$PROCESSES" 'Listening TCP sockets' ss -lntp
elif command -v netstat >/dev/null 2>&1; then
  capture "$PROCESSES" 'Listening TCP sockets' netstat -lnt
fi

section "$PROCESSES" 'ChatGPT/OpenAI processes'
ps aux 2>/dev/null | grep -Ei '[C]hatGPT|[O]penAI' >> "$PROCESSES" || true

section "$SUMMARY" 'Relevant hosts entries'
if [ -f /etc/hosts ]; then
  grep -Ein 'openai|chatgpt|oaistatic|oaiusercontent|cloudflare|auth0|workos' /etc/hosts >> "$SUMMARY" || \
    printf 'No relevant hosts entries found.\n' >> "$SUMMARY"
else
  printf '/etc/hosts not found.\n' >> "$SUMMARY"
fi

DOMAINS=(
  chatgpt.com
  auth.openai.com
  ws.chatgpt.com
  oaistatic.com
  oaiusercontent.com
  desktop.chat.openai.com
  challenges.cloudflare.com
)

for domain in "${DOMAINS[@]}"; do
  section "$REACHABILITY" "DNS $domain"
  if command -v dig >/dev/null 2>&1; then
    dig +time=5 +tries=1 A "$domain" >> "$REACHABILITY" 2>&1
    dig +time=5 +tries=1 AAAA "$domain" >> "$REACHABILITY" 2>&1
  elif command -v getent >/dev/null 2>&1; then
    getent ahosts "$domain" >> "$REACHABILITY" 2>&1
  elif command -v nslookup >/dev/null 2>&1; then
    nslookup "$domain" >> "$REACHABILITY" 2>&1
  fi

  section "$REACHABILITY" "HTTPS $domain"
  curl -4 --http1.1 -sS -o /dev/null \
    -w 'http=%{http_code} remote=%{remote_ip} dns=%{time_namelookup} connect=%{time_connect} tls=%{time_appconnect} total=%{time_total}\n' \
    --connect-timeout 10 --max-time 20 "https://$domain/" >> "$REACHABILITY" 2>&1 || true

  if command -v openssl >/dev/null 2>&1; then
    section "$REACHABILITY" "TLS certificate $domain"
    printf '' | openssl s_client -connect "$domain:443" -servername "$domain" 2>/dev/null | \
      openssl x509 -noout -subject -issuer -dates -fingerprint 2>> "$REACHABILITY" >> "$REACHABILITY" || true
  fi
done

printf 'Diagnostics collected in: %s\n' "$OUTPUT_DIR"
printf '%s\n' 'Review files before sharing. They may contain local paths, IP addresses, certificate details and process metadata.'
