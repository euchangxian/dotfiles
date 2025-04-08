#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Get script directory (absolute path to dotfiles)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo -e "${GREEN}Setting up dotfiles from: $DOTFILES_DIR${NC}"

# Install Packages in Brewfile
echo -ne "${YELLOW}Install Homebrew packages? [y/N] ${NC}"
read -n 1 -r REPLY
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  brew bundle install --file="$DOTFILES_DIR/homebrew/Brewfile"
fi

# Create XDG config directory if it doesn't exist
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$XDG_CONFIG_HOME"

# Function to create symlink with confirmation
create_symlink() {
  local src="$DOTFILES_DIR/$1" # Absolute source path
  local dst_dir="$2"           # Destination directory
  local src_basename=$(basename "$src")
  local dst_path="$dst_dir/$src_basename"

  echo -ne "${YELLOW}Create symlink for $src in $dst_dir? [y/N] ${NC}"
  read -n 1 -r REPLY
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p "$dst_dir"
    pushd "$dst_dir" >/dev/null
    ln -sf "$src" .
    popd >/dev/null
    echo -e "${GREEN}Created symlink $dst_path -> $src${NC}"
  else
    echo -e "${RED}Skipped: $src${NC}"
  fi
  echo # Newline after to separate consecutive setups.
}

# Home directory dotfiles
echo -e "\n${BLUE}${BOLD}========== SETTING UP HOME DIRECTORY DOTFILES ==========${NC}"
create_symlink "zsh/.zshrc" "$HOME"
create_symlink "git/.gitconfig" "$HOME"
create_symlink "git/.gitignore_global" "$HOME"
create_symlink "grc" "$HOME"

# .config directory dotfiles
echo -e "\n${BLUE}${BOLD}========== SETTING UP .CONFIG DIRECTORY DOTFILES ==========${NC}"
create_symlink "starship.toml" "$XDG_CONFIG_HOME"
create_symlink "wezterm" "$XDG_CONFIG_HOME"
create_symlink "nvim" "$XDG_CONFIG_HOME"
create_symlink "fzf-git.sh" "$XDG_CONFIG_HOME"
create_symlink "bat" "$XDG_CONFIG_HOME"
create_symlink "rclone" "$XDG_CONFIG_HOME"
create_symlink "pokemon-colorscripts" "$XDG_CONFIG_HOME"
create_symlink "shell-color-scripts" "$XDG_CONFIG_HOME"

# Additional configurations
echo -e "\n${BLUE}${BOLD}========== SETTING UP ADDITIONAL CONFIGURATIONS ==========${NC}"
mkdir -p "$HOME/Library/Preferences/clangd"
create_symlink "macos/Library/Preferences/clangd/config.yaml" "$HOME/Library/Preferences/clangd"

# Install Node.js LTS for Mason LSPs
echo -e "\n${BLUE}${BOLD}========== INSTALLING NODE.JS LTS FOR MASON LSPS ==========${NC}"
echo -ne "${YELLOW}Install Node.js LTS using nvm? [y/N] ${NC}"
read -n 1 -r REPLY
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${GREEN}Installing Node.js LTS version...${NC}"
  source "$HOME/.zshrc"

  nvm install --lts
  nvm use --lts

  node_version=$(node -v)
  echo -e "${GREEN}Successfully installed Node.js $node_version${NC}"
fi
echo

echo -e "\n${BLUE}${BOLD}=========== Dotfiles setup completed successfully! ===========${NC}"
