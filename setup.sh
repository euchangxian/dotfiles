#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Get script directory (absolute path to dotfiles)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo -e "${GREEN}Setting up dotfiles from: $DOTFILES_DIR${NC}"

# Install Meslo Nerd Font for powerlevel10k
echo -e "\n${GREEN}Installing Meslo Nerd Font for powerlevel10k...${NC}"
read -p "Install Meslo Nerd Font? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  mkdir -p "$HOME/Library/Fonts"
  echo "Downloading Meslo Nerd Font..."
  pushd "$HOME/Library/Fonts"
  curl -L 'https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf' -o "MesloLGS NF Regular.ttf"
  curl -L 'https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf' -o "MesloLGS NF Bold.ttf"
  curl -L 'https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf' -o "MesloLGS NF Italic.ttf"
  curl -L 'https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf' -o "MesloLGS NF Bold Italic.ttf"
  popd
  echo -e "${GREEN}Meslo Nerd Font installed successfully!${NC}"
fi

# Install Brewfile
# sudo is required for certain installations like Docker
read -p "Install Homebrew packages? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo brew bundle install --file="$DOTFILES_DIR/homebrew/Brewfile"
fi

# Create XDG config directory if it doesn't exist
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$XDG_CONFIG_HOME"

# Function to create symlink with confirmation
create_symlink() {
  local src="$DOTFILES_DIR/$1" # Absolute source path
  local dst_dir="$2"           # Destination directory

  read -p "Create symlink for $src in $dst_dir? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p "$dst_dir"
    pushd "$dst_dir"
    ln -sf "$src" .
    popd
    echo -e "${GREEN}Created symlink $dst_dir -> $src${NC}"
  else
    echo -e "${RED}Skipped: $src${NC}"
  fi
}

# Home directory dotfiles
echo -e "\n${GREEN}Creating symlinks for home directory dotfiles...${NC}"
create_symlink "zsh/.zshrc" "$HOME"
create_symlink "zsh/.p10k.zsh" "$HOME"
create_symlink "git/.gitconfig" "$HOME"
create_symlink "git/.gitignore_global" "$HOME"

# .config directory dotfiles
echo -e "\n${GREEN}Creating symlinks for .config directory dotfiles...${NC}"
create_symlink "wezterm" "$XDG_CONFIG_HOME"
create_symlink "nvim" "$XDG_CONFIG_HOME"
create_symlink "bat" "$XDG_CONFIG_HOME"

# Additional configurations
echo -e "\n${GREEN}Creating symlinks for additional configurations...${NC}"
create_symlink "grc/.grc" "$HOME"
create_symlink "grc/.grc.conf" "$HOME"

# Create symlink for clangd config
mkdir -p "$HOME/Library/Preferences/clangd"
create_symlink "macos/Library/Preferences/clangd/config.yaml" "$HOME/Library/Preferences/clangd"

echo -e "\n${GREEN}Dotfiles setup completed successfully!${NC}"

# Reminder to configure terminal font
echo -e "\n${GREEN}Remember to set your terminal font to 'MesloLGS NF' for powerlevel10k to display correctly${NC}"
