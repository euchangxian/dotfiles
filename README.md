# dotfiles

DOTFILES

## Prerequisites

1. Install iTerm2

Navigate to <https://iterm2.com/index.html> and click the huge "Download" button.

2. Install oh-my-zsh

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

3. Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Setup

```bash
# Follow the prompts in the script.
bash setup.sh
```

## Post Setup

1. Configure terminal to use Meslo Nerd Font

2. Install node. Necessary for LSPs.

```bash
nvm install --lts
```

## Notes

- Root password is necessary for `Docker` installation
- Any new symlinks to be created must be added into `setup.sh`; script is
  hard-coded. No plans to update yet, since it is unlikely that I will have many
  new config files to manage.
- Pre/Post-installation steps are not 100% certain. Will update.
- Exploring alternative terminal emulators like Kitty, since iTerm2 settings
  have to be configured using the GUI.
