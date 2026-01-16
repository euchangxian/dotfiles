# =============================================================================
#                               OS Detection
# =============================================================================
IS_MAC=false
IS_LINUX=false
ZSH_SHARE_DIR=""

if [[ "$OSTYPE" == "darwin"* ]]; then
  IS_MAC=true
  ZSH_SHARE_DIR="/opt/homebrew/share"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  IS_LINUX=true
  ZSH_SHARE_DIR="/usr/share"
fi

# =============================================================================
#                               Path & Exports
# =============================================================================
export ZSH="$HOME/.oh-my-zsh"

# Set default config/data directory
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"

# --- Dynamic Path Loading ---
# Homebrew (macOS)
if [[ "$IS_MAC" == "true" ]]; then
  # Add Homebrew GCC/Tools
  export PATH="/opt/homebrew/bin:$PATH"

  # Use Homebrew GCC
  export PATH="/usr/homebrew/opt/gcc/bin:$PATH"

  export GOROOT="/opt/homebrew/opt/go/libexec"

  # GNU-time
  export PATH="/opt/homebrew/opt/gnu-time/libexec/gnubin:$PATH"

  # Use GNU-make: gmake as make
  export PATH="/opt/homebrew/opt/make/libexec/gnubin:$PATH"

  # Use brew M4
  export PATH="/opt/homebrew/opt/m4/bin:$PATH"

  # Boost libraries and headers location
  export BOOST_ROOT="/opt/homebrew/Cellar"

  alias rosetta="arch -x86_64"
fi

if [[ "$IS_LINUX" == "true" ]]; then

fi

# Common Paths
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"

# NVM Configuration
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# =============================================================================
#                               Init Shell
# =============================================================================
plugins=(gnu-utils colored-man-pages gitfast)
source $ZSH/oh-my-zsh.sh

# --- Dynamic Plugin Sourcing ---
# Auto Suggestions
if [ -f "$ZSH_SHARE_DIR"/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source "$ZSH_SHARE_DIR"/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=244,bold"

 # Bind shift-tab to accept Auto Suggestions
bindkey '^[[Z' autosuggest-accept

# Syntax Highlighting
if [ -f "$ZSH_SHARE_DIR"/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source "$ZSH_SHARE_DIR"/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# fzf
source <(fzf --zsh)
[ -f $XDG_CONFIG_HOME/fzf-git.sh/fzf-git.sh ] && source $XDG_CONFIG_HOME/fzf-git.sh/fzf-git.sh

# fzf-tab
autoload -U compinit; compinit
source $XDG_CONFIG_HOME/fzf-tab/fzf-tab.plugin.zsh

# fzf-tab configuration
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
# NOTE: don't use escape sequences (like '%F{red}%d%f') here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# custom fzf flags
# NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default
zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=btab:accept
# To make fzf-tab follow FZF_DEFAULT_OPTS.
# NOTE: This may lead to unexpected behavior since some flags break this plugin. See Aloxaf/fzf-tab#455.
zstyle ':fzf-tab:*' use-fzf-default-opts yes
# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'

# =============================================================================
#                              Helper Functions
# =============================================================================
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
NC="\e[0m"

function info() { echo -e "[${GREEN}INFO${NC}] $@" ; }
function debug() { echo -e "[${MAGENTA}DEBUG${NC}] $@" ; }
function warn() { echo -e "[${YELLOW}WARN${NC}] $@" ; }
function run_cmd() { echo -e "[${CYAN}CMD${NC}] $@" ; "$@" ; }
function error() { echo -e "[${RED}ERROR${NC}] $@" >&2 ; }

# --- Cross-Platform Clipboard Helper ---
function _copy_cmd() {
  if [[ "$IS_MAC" == "true" ]]; then
    pbcopy
  else
    # Try xsel, fallback to xclip or wl-copy if needed
    if command -v xsel &> /dev/null; then
      xsel --clipboard --input
    elif command -v wl-copy &> /dev/null; then
      wl-copy
    else
      error "No clipboard tool found (install xsel or wl-copy)"
    fi
  fi
}

# Make and Change Directory (take makes this obsolete, but muscle memory...)
function mkcdir () {
  if [ "$#" -ne 1 ]; then
    error "usage: mkcdir <DIRECTORY_NAME>";
    return 1;
  fi
  mkdir -p "$1" && cd "$1"
}

# Copy file content to clipboard
function clip () {
  if [ "$#" -ne 1 ]; then
    error "usage: clip <FILE_NAME>";
    return 1;
  fi
  bat --plain --color=never "$1" | _copy_cmd
}

# Copy terminal buffer to clipboard
function bufftoclip() {
  if [ "$#" -ne 0 ]; then
    error "usage: bufftoclip";
    return 1;
  fi
  print -n "$BUFFER" | _copy_cmd
}

# Copy terminal buffer using CMD-Y
zle -N bufftoclip
bindkey '^o' bufftoclip

# =============================================================================
#                                Tool Functions
# =============================================================================

function cargo-update() {
  run_cmd cargo install $(cargo install --list | awk '/:$/ { print $1; }')
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
  local command="$1"
  shift
  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo $'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}

function rgd() {
  if [[ "$#" -eq 0 ]]; then error "Usage: rgd <PATTERN>"; return 1; fi
  rg --json "$1" | delta
}

function rgb() {
  if [[ "$#" -eq 0 ]]; then error "Usage: rgb <PATTERN>"; return 1; fi
  rg -l "$1" | fzf --preview="bat {}" --bind "enter:execute(bat {})"
}

function jwt() {
    if [ -z "$1" ]; then error "Usage: jwt <JWT_TOKEN>"; return 1; fi
    echo "$1" | jq -R 'split(".") | .[0,1] | @base64d | fromjson' 2>/dev/null || error "Invalid JWT token"
}

function runcpp() {
  if [[ "$#" -eq 0 ]]; then
    error "Usage: runcpp <FILE_NAME>";
    return 1;
  fi

  local cpp_file="$1"
  local executable="${cpp_file%.cpp}.out"
  if clang++ -std=c++23 -stdlib=libc++ -fexperimental-library -O3 -DDEBUG -o "$executable" "$cpp_file"; then
    ./"$executable"
    rm "$executable"
  else
    error "Compilation failed";
    return 1;
  fi
}

function runrs() {
  if [[ "$#" -eq 0 ]]; then
    error "Usage: runrs <FILE_NAME>";
    return 1;
  fi

  local rust_file="$1"
  local executable="${rust_file%.rs}.out"
  if rustc -O -o "$executable" "$rust_file"; then
    ./"$executable"
    rm "$executable"
  else
    error "Compilation failed";
    return 1
  fi
}

function runocaml() {
  if [[ "$#" -eq 0 ]]; then echo "Usage: runocaml <FILE_NAME>"; return 1; fi
  local ocaml_file="$1"
  local executable="${ocaml_file%.ml}.out"
  if ocamlopt -o "$executable" "$ocaml_file"; then
    ./"$executable"
    rm "$executable"
  else
    error "Compilation failed";
    return 1
  fi
}

# Function to sync a directory with a remote host using fswatch
function syncdir() {
  local LOCAL_DIR="$1"
  local REMOTE_DIR="$2"

  if [[ -z "$LOCAL_DIR" || -z "$REMOTE_DIR" ]]; then
    error "Usage: syncdir <LOCAL_DIR> <REMOTE_DIR>";
    return 1;
  fi

  info "Starting to watch $LOCAL_DIR and sync with $REMOTE_DIR..."

  fswatch -o "$LOCAL_DIR" | while read change; do
    rsync -avz --exclude='.git/' "$LOCAL_DIR/" "$REMOTE_DIR"
    info "Synced changes from $LOCAL_DIR to $REMOTE_DIR"
  done
}

# =============================================================================
#                               Environment & UI
# =============================================================================

# Less & Bat
export LESS_TERMCAP_mb=$'\e[1;31m'
export LESS_TERMCAP_md=$'\e[1;36m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;44;33m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;32m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS='--ignore-case --LONG-PROMPT --RAW-CONTROL-CHARS --tabs=4 --window=4'
export BAT_PAGER="less $LESS"
export BAT_THEME=tokyonight_night

# Man Pager (use NeoVim)
export MANPAGER='nvim +Man!'
export MANWIDTH=999

# FZF Defaults
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}"
export FZF_ALT_C_COMMAND="fd --type=d -hidden --strip-cwd-prefix --exclude .git"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# GitLab GPG Key compatibility with Powerlevel10k
export GPG_TTY=$(tty)

# =============================================================================
#                               Aliases
# =============================================================================
alias vim='nvim'

alias cat='bat'

# alias ls='eza --grid --color=always --icons=always --long --git --no-filesize --no-time --no-user --no-permissions'
alias ls='eza --grid --color=always --icons=always'
alias tree='eza --tree'

alias cdr='cd $(git rev-parse --show-toplevel)'

# Starship Prompt: https://starship.rs/
eval "$(starship init zsh)"

# Zoxide - fast cd
export _ZO_DATA_DIR="$XDG_DATA_HOME"
eval "$(zoxide init zsh)"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
