#!/usr/bin/env bash
###############################################################################
# start.sh — Wrapper to start the Linux-Priv laboratory environment
###############################################################################
set -euo pipefail

# ANSI color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

echo -e "${BLUE}[*] Checking prerequisites...${RESET}"

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}[-] Error: Docker is not installed.${RESET}"
    exit 1
fi

# Check if docker daemon is running
if ! docker info &> /dev/null; then
    echo -e "${RED}[-] Error: Docker daemon is not running. Please start Docker.${RESET}"
    exit 1
fi

echo -e "${GREEN}[+] Prerequisites verified successfully.${RESET}"
echo -e "${BLUE}[*] Starting Linux-Priv Lab (vulnerable-ubuntu)...${RESET}"

# Run docker compose
docker compose up -d --build

echo -e "\n${GREEN}====================================================================${RESET}"
echo -e "${GREEN}      SUCCESS: Linux Privilege Escalation Lab is Running!          ${RESET}"
echo -e "${GREEN}====================================================================${RESET}"
echo -e "${YELLOW}Credentials & Connection:${RESET}"
echo -e " - Username: ${BLUE}student${RESET}"
echo -e " - Password: ${BLUE}student123${RESET}"
echo -e " - SSH Access: ${BLUE}ssh student@localhost -p 2222${RESET}"
echo -e " - Container Terminal: ${BLUE}docker exec -it linux-priv-esc-lab su - student${RESET}"
echo -e "--------------------------------------------------------------------"
echo -e "${YELLOW}Objective: Abuse the 15 privilege escalation vectors to capture root flags.${RESET}"
echo -e "${GREEN}====================================================================${RESET}"
