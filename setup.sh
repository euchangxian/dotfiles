#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'
function header() {
  echo -e "\n${BLUE}${BOLD}========== " "$@" " ==========${NC}"
}
function info() {
  echo -e "[${GREEN}INFO${NC}] " "$@"
}
function debug() {
  echo -e "[${MAGENTA}DEBUG${NC}] " "$@"
}
function warn() {
  echo -e "[${YELLOW}WARN${NC}] " "$@"
}
function error() {
  echo -e "[${RED}ERROR${NC}] " "$@" >&2
  exit 1
}
function ask() {
  echo -ne "[${BLUE}PROMPT${NC}] " "$@" " [y|${BOLD}N${NC}]"
  read -n 1 -r REPLY
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    return 0
  else
    return 1
  fi
}
function run_cmd() {
  echo -e "[${CYAN}CMD${NC}] " "$@"
  # if [ ${DRY_RUN} == true ]; then
  #   return 0
  # fi
  "$@"
}
function command_exists() {
  command -v "$1" >/dev/null 2>&1
}
function on_error() {
  STATUS="$?"
  set +o errtrace
  set +o xtrace
  error "\"${BASH_COMMAND}\" failed at line $1: exited with status ${STATUS}"
}
trap 'on_error $LINENO' ERR

function usage() {
  echo "Usage: $0 [-h|--help] [--dry-run]"
  echo -e "Options:"
  echo -e "\t -h|--help: Display this help and exit"
  echo -e "\t --dry-run: Print commands without executing them. Should be specified as early as possible"
}

REPO="euchangxian/dotfiles"
VERSION="latest"
BIN_DIR="./dotty"

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

# Normalize Arch (x86_64 -> amd64, aarch64 -> arm64)
case "$ARCH" in
x86_64) ARCH="amd64" ;;
aarch64 | arm64) ARCH="arm64" ;;
*)
  error "Unsupported architecture: $ARCH"
  ;;
esac

BINARY_NAME="dotty-${OS}-${ARCH}"
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${BINARY_NAME}"

info "Bootstrapping Dotty for ${OS}/${ARCH}..."
info "Downloading from: ${DOWNLOAD_URL}"

if command -v curl >/dev/null 2>&1; then
  run_cmd curl -L -o "${BIN_DIR}/dotty" "$DOWNLOAD_URL"
elif command -v wget >/dev/null 2>&1; then
  run_cmd wget -O "${BIN_DIR}/dotty" "$DOWNLOAD_URL"
else
  error "Neither curl nor wget found."
fi

chmod +x "${BIN_DIR}/dotty"

pushd "$BIN_DIR" >/dev/null 2>&1
./dotty "$@"
popd >/dev/null 2>&1
