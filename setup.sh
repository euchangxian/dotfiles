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

# Create XDG config directory if it doesn't exist
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$XDG_CONFIG_HOME"

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

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

# Install Oh-My-ZSH if not already installed
if [ -d "$HOME/.oh-my-zsh" ]; then
  echo -e "${GREEN}Oh-My-ZSH is already installed${NC}"
else
  echo -ne "${YELLOW}Oh-My-ZSH not found. Install it? [y/N] ${NC}"
  read -n 1 -r REPLY
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
fi

# Install HomeBrew if not already installed
if command_exists brew; then
  echo -e "${GREEN}Homebrew is already installed${NC}"
else
  echo -ne "${YELLOW}Homebrew not found. Install it? [y/N] ${NC}"
  read -n 1 -r REPLY
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH if it's not already there
    if [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]] && [[ -d "/opt/homebrew/bin" ]]; then
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$HOME/.zprofile"
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  fi
fi

# Install Packages in Brewfile
if command_exists brew; then
  echo -ne "${YELLOW}Install Homebrew packages? [y/N] ${NC}"
  read -n 1 -r REPLY
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    brew bundle install --file="$DOTFILES_DIR/homebrew/Brewfile"
  fi
fi

# Home directory dotfiles
echo -e "\n${BLUE}${BOLD}========== SETTING UP HOME DIRECTORY DOTFILES ==========${NC}"
create_symlink "zsh/.zshrc" "$HOME"
create_symlink "git/.gitconfig" "$HOME"
create_symlink "git/.gitignore_global" "$HOME"
create_symlink "grc" "$HOME"

# .config directory dotfiles
echo -e "\n${BLUE}${BOLD}========== SETTING UP .CONFIG DIRECTORY DOTFILES ==========${NC}"
create_symlink "starship/starship.toml" "$XDG_CONFIG_HOME"
create_symlink "wezterm" "$XDG_CONFIG_HOME"
create_symlink "nvim" "$XDG_CONFIG_HOME"
create_symlink "fzf-git.sh" "$XDG_CONFIG_HOME"
create_symlink "bat" "$XDG_CONFIG_HOME"
create_symlink "rclone" "$XDG_CONFIG_HOME"
create_symlink "pokemon-colorscripts" "$XDG_CONFIG_HOME"
create_symlink "shell-color-scripts" "$XDG_CONFIG_HOME"
create_symlink "lazygit" "$XDG_CONFIG_HOME"

# Additional configurations
echo -e "\n${BLUE}${BOLD}========== SETTING UP ADDITIONAL CONFIGURATIONS ==========${NC}"
mkdir -p "$HOME/Library/Preferences/clangd"
create_symlink "macos/Library/Preferences/clangd/config.yaml" "$HOME/Library/Preferences/clangd"

# Install Node.js LTS for Mason LSPs
echo -e "\n${BLUE}${BOLD}========== INSTALLING NODE.JS LTS FOR MASON LSPS ==========${NC}"
if command_exists node; then
  node_version=$(node -v)
  echo -e "${GREEN}Node.js $node_version is already installed${NC}"
else
  echo -ne "${YELLOW}Node.js not found. Install Node.js using nvm? [y/N] ${NC}"
  read -n 1 -r REPLY
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command_exists nvm || [ -d "$HOME/.nvm" ]; then
      # Load nvm if needed
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

      nvm install --lts
      nvm use --lts
      node_version=$(node -v)
      echo -e "${GREEN}Successfully installed Node.js $node_version${NC}"
    else
      echo -e "${YELLOW}nvm not found. Please install nvm first to manage Node.js versions${NC}"
    fi
  fi
fi

echo
echo -e "\n${BLUE}${BOLD}=========== Dotfiles setup completed successfully! ===========${NC}"
