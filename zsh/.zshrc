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
# Oh-My-ZSH
source $ZSH/oh-my-zsh.sh

# P10k
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ZSH Auto Suggestions
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# ZSH Syntax Highlighting
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
. /opt/homebrew/etc/profile.d/z.sh

# Fuzzy Finder
source <(fzf --zsh)
source ~/.config/fzf-git.sh/fzf-git.sh

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

# FZF (Fuzzy Finder) Functions
# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
function _fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
function _fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command
# - The rest of the arguments should be passed to fzf
function _fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo $'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}

# =============================================================================
#                             PATH/Bin Variables/Other Exports
# =============================================================================
# Set GOROOT
export GOROOT=/opt/homebrew/opt/go/libexec

# Add GOBIN to PATH
export PATH=$PATH:$HOME/go/bin

# Add NVM to PATH
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

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/euchangxian/.sdkman"
[[ -s "/Users/euchangxian/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/euchangxian/.sdkman/bin/sdkman-init.sh"

# GitLab GPG Key compatibility with Powerlevel10k
export GPG_TTY=$(tty)

# Bat Theme
export BAT_THEME=tokyonight_night

# FD - find alternative
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}"

export FZF_ALT_C_COMMAND="fd --type=d -hidden --strip-cwd-prefix --exclude .git"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"
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

# Decode JWT Tokens
alias jwt="jq -R 'split(".") | .[0,1] | @base64d | fromjson'"

# Use eza instead of ls
alias ls="eza --grid --color=always --icons=always --long --git --no-filesize --no-time --no-user --no-permissions"

# Use ripgrep case-insensitively by default
alias rg="rg -i"
# =============================================================================

