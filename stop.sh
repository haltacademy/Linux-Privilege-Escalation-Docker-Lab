#!/usr/bin/env bash
###############################################################################
# stop.sh — Wrapper to stop and destroy the Linux-Priv laboratory environment
###############################################################################
set -euo pipefail

# ANSI color codes
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RESET='\033[0m'

echo -e "${BLUE}[*] Stopping and destroying Linux-Priv Lab container...${RESET}"

# Stop the container
docker compose down

echo -e "${GREEN}[+] Lab destroyed successfully and resources freed.${RESET}"
