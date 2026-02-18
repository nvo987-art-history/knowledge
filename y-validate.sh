#!/usr/bin/env bash
set -e

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo -e "${YELLOW}=== NVO987 Knowledge Validator (knowledge.nvo987.us) ===${NC}"

ERRORS=0
EXPECTED_DOMAIN="knowledge.nvo987.us"

# ------------------------
# BASIC VALIDATORS
# ------------------------

validate_json() {
  local file="$1"
  if ! jq empty "$file" 2>/dev/null; then
    echo -e "${RED}✗ JSON error:${NC} $file"
    ERRORS=$((ERRORS+1))
  else
    echo -e "${GREEN}✓ JSON OK:${NC} $file"
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

# ------------------------
# KNOWLEDGE SPECIFIKUS
# ------------------------

validate_knowledge_json() {
  local file="$1"

  local domain canonical
  domain=$(jq -r '.domain // empty' "$file")
  canonical=$(jq -r '.canonical // empty' "$file")

  if [ -n "$domain" ] && [ "$domain" != "https://$EXPECTED_DOMAIN" ]; then
    echo -e "${RED}✗ Domain mismatch:${NC} $file ($domain)"
    ERRORS=$((ERRORS+1))
  fi

  if [ -n "$canonical" ] && [[ "$canonical" != https://$EXPECTED_DOMAIN* ]]; then
    echo -e "${RED}✗ Canonical mismatch:${NC} $file ($canonical)"
    ERRORS=$((ERRORS+1))
  fi
}

# ------------------------
# .well-known CHECK
# ------------------------

check_well_known() {
  echo
  echo "Checking .well-known files..."

  local files=(
    ".well-known/knowledge.json"
    ".well-known/ai.json"
    ".well-known/security.txt"
  )

  for f in "${files[@]}"; do
    if [ ! -f "$f" ]; then
      echo -e "${RED}✗ Missing:${NC} $f"
      ERRORS=$((ERRORS+1))
    else
      echo -e "${GREEN}✓ Found:${NC} $f"
    fi
  done
}

# ------------------------
# SCAN
# ------------------------

echo "Scanning knowledge files..."

find . -type f ! -path "./.git/*" ! -path "./.github/*" | while read -r file; do
  case "$file" in
    *.json)
      validate_json "$file"
      [[ "$file" == *knowledge.json ]] && validate_knowledge_json "$file"
      ;;
    *.txt)
      validate_txt "$file"
      ;;
  esac
done

check_well_known

echo
if [ "$ERRORS" -gt 0 ]; then
  echo -e "${RED}✗ Knowledge validation failed: $ERRORS error(s).${NC}"
  exit 1
else
  echo -e "${GREEN}✓ knowledge.nvo987.us fully validated.${NC}"
fi
