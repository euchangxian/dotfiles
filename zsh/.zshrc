# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

plugins=()

# ============================ Init Shell =====================================
source $ZSH/oh-my-zsh.sh
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
. /opt/homebrew/etc/profile.d/z.sh

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# ============================ Function Definitions ===========================
# Make and Change Directory
function mkcdir () {
  if [ "$#" -ne 1 ]; then
    echo "usage: mkcdir DIRECTORY_NAME"
    return 1
  fi
  mkdir $1 && cd $1
}

# Copy file content to clipboard
function clip () {
  if [ "$#" -ne 1 ]; then
    echo "usage: clip FILE_NAME"
    return 1
  fi
  cat $1 | pbcopy
}

# Adds the module to mod.rs, then opens the file in Vim
function vimr() {
  if [ "$#" -ne 1 ]; then
    echo "usage: vimr FILE_NAME"
    return 1
  fi
  # Get the filename without the .rs extension
  local module_name="${1%.rs}"

  # Append the module to mod.rs
  echo "pub mod $module_name;" >> mod.rs

  # Open the file in Vim
  vim "$1"
}


# =============================================================================
#                             PATH/Bin Variables
# =============================================================================
# Set GOROOT
export GOROOT=/opt/homebrew/opt/go/libexec

# Add GOBIN to PATH
export PATH=$PATH:$HOME/go/bin

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# Add Mason executables to PATH
export PATH=$PATH:$HOME/.local/share/nvim/mason/bin

# Maven
export M2_HOME=/opt/homebrew/bin/mvn
export PATH=$JAVA_HOME/bin:$M2_HOME/bin:$PATH

# PostgreSQL
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"

# OpenSSL
export PATH="/opt/homebrew/opt/openssl@3.0/bin:$PATH"
# =============================================================================

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/euchangxian/miniforge3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
  eval "$__conda_setup"
else
  if [ -f "/Users/euchangxian/miniforge3/etc/profile.d/conda.sh" ]; then
    . "/Users/euchangxian/miniforge3/etc/profile.d/conda.sh"
  else
    export PATH="/Users/euchangxian/miniforge3/bin:$PATH"
  fi
fi
unset __conda_setup

if [ -f "/Users/euchangxian/miniforge3/etc/profile.d/mamba.sh" ]; then
  . "/Users/euchangxian/miniforge3/etc/profile.d/mamba.sh"
fi
# <<< conda initialize <<<


# ============================== Alias Definitions ============================
# Use neo-vim by default
alias vim="nvim"

# Use bat instead of built-in cat
alias cat="bat"

# Compile C++ with GCC
alias gpp="g++-14 -std=c++20 -O3 -march=native"

# Compile C++ files with clang++
alias cpp="clang++ -std=c++20 -stdlib=libc++"

alias jwt="jq -R 'split(".") | .[0,1] | @base64d | fromjson'"

# =============================================================================

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/euchangxian/.sdkman"
[[ -s "/Users/euchangxian/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/euchangxian/.sdkman/bin/sdkman-init.sh"

# GitLab GPG Key compatibility with Powerlevel10k
export GPG_TTY=$(tty)
