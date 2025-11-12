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
  if [ ${DRY_RUN} == true ]; then
    return 0
  fi
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

DRY_RUN=false

OH_MY_ZSH_URI="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
HOMEBREW_URI="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

HOME_DOTFILES=(
  "zsh/.zshrc"
  "zsh/.zprofile"
  "git/.gitconfig"
  "git/.gitignore_global"
  "tmux/.tmux.conf"
  "grc"
)

XDG_CONFIG_DOTFILES=(
  "ghostty"
  "starship/starship.toml"
  "nvim"
  "fzf-git.sh"
  "bat"
  "rclone"
  "pokemon-colorscripts"
  "shell-color-scripts"
  "lazygit"
)

# <src dest>
ADDITIONAL_DOTFILES=(
  "macos/Library/Preferences/clangd/config.yaml $HOME/Library/Preferences/clangd"
)

# --- Installation Functions ---
function install_oh_my_zsh() {
  info "Checking Oh-My-ZSH installation..."
  if [ -d "$HOME/.oh-my-zsh" ]; then
    info "Oh-My-ZSH is already installed."
    return 0
  fi

  if ! ask "Oh-My-ZSH not found. Install it?"; then
    return 0
  fi

  run_cmd /bin/bash -c "$(curl -fsSL ${OH_MY_ZSH_URI})"
}

function install_homebrew() {
  info "Checking Homebrew installation..."
  if command_exists brew; then
    info "Homebrew is already installed."
    return 0
  fi

  if ! ask "Homebrew not found. Install it?"; then
    return 0
  fi

  run_cmd /bin/bash -c "$(curl -fsSL ${HOMEBREW_URI})"

  if ! command_exists brew; then
    error "Homebrew installation failed: 'brew' command not found."
  fi

  run_cmd eval "$(/opt/homebrew/bin/brew shellenv)" || error "Failed to evaluate Homebrew shellenv."

  if grep -q 'eval "$(/opt/homebrew/bin/brew shellenv)"' "$HOME/.zprofile" 2>/dev/null; then
    info "Homebrew shellenv already in ~/.zprofile."
    return 0
  fi

  info "Adding Homebrew shellenv to ~/.zprofile..."
  run_cmd 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$HOME/.zprofile"
}

function install_brew_packages() {
  info "Checking for Brewfile packages..."
  if ! command_exists brew; then
    warn "Homebrew not installed. Skipping Brewfile package installation."
    return 0
  fi

  if ! [ -f "${DOTFILES_DIR}/homebrew/Brewfile" ]; then
    warn "Brewfile not found at '${DOTFILES_DIR}/homebrew/Brewfile'. Skipping Brewfile package installation."
    return 0
  fi

  if ! ask "Install Homebrew packages from Brewfile?"; then
    return 0
  fi

  run_cmd brew bundle install --file="${DOTFILES_DIR}/homebrew/Brewfile"
}

function install_node_lts() {
  info "Checking Node.js LTS for Mason LSPs..."
  if command_exists node; then
    node_version=$(node -v)
    info "Node.js $node_version is already installed."
    return 0
  fi

  if ! ask "Node.js not found. Install Node.js using nvm?"; then
    return 0
  fi

  # NVM should be in the Brewfile. Sanity Check here.
  if ! command_exists nvm && ! [ -d "$HOME/.nvm" ]; then
    warn "nvm not found. Please install nvm first if you want to manage Node.js versions. Skipping Node.js installation."
    return 0
  fi

  if [ -s "$HOME/.nvm/nvm.sh" ] && ! type nvm &>/dev/null; then
    run_cmd export NVM_DIR="$HOME/.nvm"
    info "Sourcing nvm..."
    run_cmd \. "${NVM_DIR}/nvm.sh"
  fi

  if ! type nvm &>/dev/null; then
    error "nvm command not available after sourcing. Cannot install Node.js."
  fi

  run_cmd nvm install --lts
  run_cmd nvm use --lts
  info "Successfully installed Node.js $(node -v)."
}

function create_symlink() {
  local src="${DOTFILES_DIR}/$1"
  local dst_dir="$2"
  local dst_path="$dst_dir/$(basename "${src}")"

  if ! ask "Create symlink for $src in $dst_dir?"; then
    info "Skipped: $src"
    return 0
  fi

  run_cmd mkdir -p "$dst_dir"
  (pushd "$dst_dir" >/dev/null &&
    run_cmd ln -sf "$src" .) || error "Failed to create symlink for $src"
  info "Created symlink $dst_path -> $src"
}

function parse_args() {
  while [[ $# -ge 1 ]]; do
    key="$1"
    case "${key}" in
    -h | --help)
      usage
      exit 0
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    *)
      usage
      error "unknown option: $1"
      ;;
    esac
    shift
  done
}

parse_args "$@"
header "Setting up dotfiles from: ${DOTFILES_DIR}"
install_oh_my_zsh
install_homebrew
install_brew_packages
install_node_lts

# Home directory dotfiles
header "SETTING UP HOME DIRECTORY DOTFILES"
for src_path in "${HOME_DOTFILES[@]}"; do
  create_symlink "${src_path}" "${HOME}"
  echo ""
done

# .config directory dotfiles
header "SETTING UP .CONFIG DIRECTORY DOTFILES"
run_cmd mkdir -p "${XDG_CONFIG_HOME}"
for src_path in "${XDG_CONFIG_DOTFILES[@]}"; do
  create_symlink "${src_path}" "${XDG_CONFIG_HOME}"
  echo ""
done

# Additional configurations
header "SETTING UP ADDITIONAL CONFIGURATIONS"
for file_pair in "${ADDITIONAL_DOTFILES[@]}"; do
  read -r src_path dest_dir <<<"${file_pair}"
  create_symlink "${src_path}" "${dest_dir}"
  echo ""
done

header "Dotfiles setup completed successfully!"
