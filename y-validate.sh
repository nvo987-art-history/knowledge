#!/usr/bin/env bash

set -e

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo -e "${YELLOW}=== NVO987 Universal Validator ===${NC}"

ERRORS=0

validate_json() {
  local file="$1"
  if ! jq empty "$file" 2>/dev/null; then
    echo -e "${RED}✗ JSON error:${NC} $file"
    ERRORS=$((ERRORS+1))
  else
    echo -e "${GREEN}✓ JSON OK:${NC} $file"
  fi
}

validate_ndjson() {
  local file="$1"
  local line=0
  while IFS= read -r row; do
    line=$((line+1))
    if ! echo "$row" | jq empty 2>/dev/null; then
      echo -e "${RED}✗ NDJSON error:${NC} $file (line $line)"
      ERRORS=$((ERRORS+1))
    fi
  done < "$file"
  echo -e "${GREEN}✓ NDJSON OK:${NC} $file"
}

validate_xml() {
  local file="$1"
  if ! xmllint --noout "$file" 2>/dev/null; then
    echo -e "${RED}✗ XML error:${NC} $file"
    ERRORS=$((ERRORS+1))
  else
    echo -e "${GREEN}✓ XML OK:${NC} $file"
  fi
}

validate_html() {
  local file="$1"
  if ! tidy -errors -q "$file" 2>/dev/null; then
    echo -e "${YELLOW}⚠ HTML warnings:${NC} $file"
  else
    echo -e "${GREEN}✓ HTML OK:${NC} $file"
  fi
}

validate_txt() {
  local file="$1"
  if [[ ! -s "$file" ]]; then
    echo -e "${RED}✗ TXT empty:${NC} $file"
    ERRORS=$((ERRORS+1))
  else
    echo -e "${GREEN}✓ TXT OK:${NC} $file"
  fi
}

echo "Scanning files..."

while IFS= read -r file; do
  case "$file" in
    *.json)
      validate_json "$file"
      ;;
    *.ndjson)
      validate_ndjson "$file"
      ;;
    *.xml)
      validate_xml "$file"
      ;;
    *.html)
      validate_html "$file"
      ;;
    *.txt)
      validate_txt "$file"
      ;;
  esac
done < <(find . -type f ! -path "./.git/*")

echo
if [ "$ERRORS" -gt 0 ]; then
  echo -e "${RED}✗ Validation failed: $ERRORS error(s) found.${NC}"
  exit 1
else
  echo -e "${GREEN}✓ All files validated successfully.${NC}"
fi
