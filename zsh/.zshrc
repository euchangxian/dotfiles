# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

plugins=(colored-man-pages)

# ============================ Init Shell =====================================
# Oh-My-ZSH
source $ZSH/oh-my-zsh.sh

# ZSH Auto Suggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=244,bold"
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
bindkey '^[[Z' autosuggest-accept # Bind shift-tab to accept Auto Suggestions

# ZSH Syntax Highlighting
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
. /opt/homebrew/etc/profile.d/z.sh

# Fuzzy Finder
source <(fzf --zsh)
source ~/.config/fzf-git.sh/fzf-git.sh

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

# Ripgrep and displays results in delta pager.
function rgd() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: rgd <pattern>"
    return 1
  fi
  rg --json "$1" | delta
}

# Ripgrep and preview files that matches pattern using FZF. Then, bat can be
# used to browse the file.
function rgb() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: rgb <pattern>"
    return 1
  fi
  rg -l "$1" | fzf --preview="bat {}" --bind "enter:execute(bat {})"
}

function jwt() {
    if [ -z "$1" ]; then
        echo "Usage: jwt <token>"
        return 1
    fi
    echo "$1" | jq -R 'split(".") | .[0,1] | @base64d | fromjson' 2>/dev/null || echo "Invalid JWT token"
}

function runcpp() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: runcpp <FILE_NAME.cpp>"
        return 1
    fi

    local cpp_file="$1"
    local executable="${cpp_file%.cpp}"

    # Compile C++ file
    if clang++ -std=c++23 -stdlib=libc++ -fexperimental-library -O3 -DDEBUG -o "$executable" "$cpp_file"; then ./"$executable"
        rm "$executable"
    else
        echo "Compilation failed"
        return 1
    fi
}

function runrs() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: runrs <FILE_NAME.cpp>"
        return 1
    fi

    local rust_file="$1"
    local executable="${rust_file%.rs}"

    # Compile Rust file
    if rustc -O -o "$executable" "$rust_file"; then
        ./"$executable"
        rm "$executable"
    else
        echo "Compilation failed"
        return 1
    fi
}

# Function to sync a directory with a remote host using fswatch
function syncdir() {
    local LOCAL_DIR="$1"    # Local directory path to watch
    local REMOTE_DIR="$2"   # Remote directory path to sync with

    if [[ -z "$LOCAL_DIR" || -z "$REMOTE_DIR" ]]; then
        echo "Usage: syncdir <local_directory> <remote_directory>"
        return 1
    fi

    echo "Starting to watch $LOCAL_DIR and sync with $REMOTE_DIR on remote host..."

    # Start fswatch to monitor changes and sync with remote host
    fswatch -o "$LOCAL_DIR" | while read change; do
        rsync -avz --exclude='.git/' "$LOCAL_DIR/" "$REMOTE_DIR"
        echo "Synced changes from $LOCAL_DIR to $REMOTE_DIR"
    done
}

# =============================================================================
#                   PATH/Bin Variables/Other Exports
# =============================================================================

# LESS flags.
export LESS_TERMCAP_mb=$'\E[1;31m'     # begin bold
export LESS_TERMCAP_md=$'\E[1;36m'     # begin blink
export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;44;33m' # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # reset underline
export LESS='--ignore-case --clear-screen --CLEAR-SCREEN --LONG-PROMPT --RAW-CONTROL-CHARS --tabs=4 --window=4'
export BAT_PAGER="less $LESS"

# Set default config directory
export XDG_CONFIG_HOME="$HOME/.config"

# Add homebrew binaries to PATH
export PATH="/opt/homebrew/bin:$PATH"

# Add Wezterm CLI to PATH
export PATH="$PATH:/Applications/WezTerm.app/Contents/MacOS"

# Set GOROOT
export GOROOT="/opt/homebrew/opt/go/libexec"

# Add GOBIN to PATH
export PATH="$PATH:$HOME/go/bin"

# Add Cargo Bin to path.
export PATH="$PATH:$HOME/.cargo/bin"

# Use GCC
export PATH="/usr/local/bin:$PATH"

# Add NVM to PATH
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# Add Mason executables to PATH
export PATH="$PATH:$HOME/.local/share/nvim/mason/bin"

# Maven
export M2_HOME="/opt/homebrew/bin/mvn"
export PATH="$JAVA_HOME/bin:$M2_HOME/bin:$PATH"

# PostgreSQL
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"

# OpenSSL
export PATH="/opt/homebrew/opt/openssl@3.0/bin:$PATH"

# GNU-time
export PATH="/opt/homebrew/opt/gnu-time/libexec/gnubin:$PATH"

export LDFLAGS="-L/usr/local/opt/openssl/lib"
export CPPFLAGS="-I/usr/local/opt/openssl/include"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# GitLab GPG Key compatibility with Powerlevel10k
export GPG_TTY=$(tty)

# Use NVIm as man pager
export MANPAGER='nvim +Man!'
export MANWIDTH=999

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
__conda_setup="$("$HOME/miniforge3/bin/conda" 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
  eval "$__conda_setup"
else
  if [ -f "$HOME/miniforge3/etc/profile.d/conda.sh" ]; then
    . "$HOME/miniforge3/etc/profile.d/conda.sh"
  else
    export PATH="$HOME/miniforge3/bin:$PATH"
  fi
fi
unset __conda_setup

if [ -f "$HOME/miniforge3/etc/profile.d/mamba.sh" ]; then
  . "$HOME/miniforge3/etc/profile.d/mamba.sh"
fi
# <<< conda initialize <<<

# ============================== Alias Definitions ============================
# Use neo-vim by default
alias vim='nvim'

# Use bat instead of built-in cat
alias cat='bat'

# Compile C++ with GCC
alias gpp='g++-14 -std=c++23 -O3'

# Compile C++ files with clang++
alias cpp='clang++ -std=c++20 -stdlib=libc++'

# Use eza instead of ls
# alias ls='eza --grid --color=always --icons=always --long --git --no-filesize --no-time --no-user --no-permissions'
alias ls='eza --grid --color=always --icons=always'

# cd to Git Repository Project root
alias cdr='cd $(git rev-parse --show-toplevel)'

alias gfixup='git add . && git commit -m 'fixup' && git rebase -i HEAD~2'
# =============================================================================

# Forgot what was this for...
. "$HOME/.local/bin/env"

# https://starship.rs/
eval "$(starship init zsh)"
