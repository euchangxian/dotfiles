export ZSH="$HOME/.oh-my-zsh"

plugins=(gnu-utils colored-man-pages gitfast)

# ============================ Init Shell =====================================
# Oh-My-ZSH
source $ZSH/oh-my-zsh.sh

# Set default config/data directory.
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"

# ZSH Auto Suggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=244,bold"
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
bindkey '^[[Z' autosuggest-accept # Bind shift-tab to accept Auto Suggestions

# ZSH Syntax Highlighting
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Fuzzy Finder
source <(fzf --zsh)
source ~/.config/fzf-git.sh/fzf-git.sh

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
zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
# To make fzf-tab follow FZF_DEFAULT_OPTS.
# NOTE: This may lead to unexpected behavior since some flags break this plugin. See Aloxaf/fzf-tab#455.
zstyle ':fzf-tab:*' use-fzf-default-opts yes
# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'

# ======================= Helper Variables/Functions ===========================
RED="\e[31m"
MAGENTA="\e[35m"
YELLOW="\e[33m"
GREEN="\e[32m"
NC="\e[0m"

function info() {
  echo -e "[${GREEN}INFO${NC}] $@"
}
function debug() {
  echo -e "[${MAGENTA}DEBUG${NC}] $@"
}
function warn() {
  echo -e "[${YELLOW}WARN${NC}] $@"
}
function error() {
  echo -e "[${RED}ERROR${NC}] $@" >&2
}

# ============================ Function Definitions ===========================
# Make and Change Directory
function mkcdir () {
  if [ "$#" -ne 1 ]; then
    error "usage: mkcdir <DIRECTORY_NAME>"
    return 1
  fi
  mkdir -p "$1" && cd "$1"
}

# Copy file content to clipboard
function clip () {
  if [ "$#" -ne 1 ]; then
    error "usage: clip <FILE_NAME>"
    return 1
  fi
  bat --plain --color=never "$1" | pbcopy
}

# Copy terminal buffer to clipboard
function bufftoclip() {
  if [ "$#" -ne 0 ]; then
    error "usage: bufftoclip"
    return 1
  fi
  print -n "$BUFFER" | pbcopy
}

# Copy terminal buffer using CMD-Y
zle -N bufftoclip
bindkey '^o' bufftoclip

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

# Ripgrep and displays results in delta pager.
function rgd() {
  if [[ "$#" -eq 0 ]]; then
    error "Usage: rgd <PATTERN>"
    return 1
  fi
  rg --json "$1" | delta
}

# Ripgrep and preview files that matches pattern using FZF. Then, bat can be
# used to browse the file.
function rgb() {
  if [[ "$#" -eq 0 ]]; then
    error "Usage: rgb <PATTERN>"
    return 1
  fi
  rg -l "$1" | fzf --preview="bat {}" --bind "enter:execute(bat {})"
}

function jwt() {
    if [ -z "$1" ]; then
        error "Usage: jwt <JWT_TOKEN>"
        return 1
    fi
    echo "$1" | jq -R 'split(".") | .[0,1] | @base64d | fromjson' 2>/dev/null || error "Invalid JWT token"
}

function runcpp() {
    if [[ "$#" -eq 0 ]]; then
        error "Usage: runcpp <FILE_NAME>"
        return 1
    fi

    local cpp_file="$1"
    local executable="${cpp_file%.cpp}"

    if clang++ -std=c++23 -stdlib=libc++ -fexperimental-library -O3 -DDEBUG -o "$executable" "$cpp_file"; then ./"$executable"
        rm "$executable"
    else
        error "Compilation failed"
        return 1
    fi
}

function runrs() {
    if [[ "$#" -eq 0 ]]; then
        error "Usage: runrs <FILE_NAME>"
        return 1
    fi

    local rust_file="$1"
    local executable="${rust_file%.rs}"

    if rustc -O -o "$executable" "$rust_file"; then
        ./"$executable"
        rm "$executable"
    else
        error "Compilation failed"
        return 1
    fi
}

function runocaml() {
    if [[ "$#" -eq 0 ]]; then
        echo "Usage: runocaml <FILE_NAME>"
        return 1
    fi

    local ocaml_file="$1"
    local executable="${ocaml_file%.ml}"

    if ocamlopt -o "$executable" "$ocaml_file"; then
        ./"$executable"
        rm "$executable"
    else
        error "Compilation failed"
        return 1
    fi
}

# Function to sync a directory with a remote host using fswatch
function syncdir() {
    local LOCAL_DIR="$1"
    local REMOTE_DIR="$2"

    if [[ -z "$LOCAL_DIR" || -z "$REMOTE_DIR" ]]; then
        error "Usage: syncdir <LOCAL_DIR> <REMOTE_DIR>"
        return 1
    fi

    info "Starting to watch $LOCAL_DIR and sync with $REMOTE_DIR on remote host..."

    # Start fswatch to monitor changes and sync with remote host
    fswatch -o "$LOCAL_DIR" | while read change; do
        rsync -avz --exclude='.git/' "$LOCAL_DIR/" "$REMOTE_DIR"
        info "Synced changes from $LOCAL_DIR to $REMOTE_DIR"
    done
}

# =============================================================================
#                   PATH/Bin Variables/Other Exports
# =============================================================================

# LESS flags.
export LESS_TERMCAP_mb=$'\e[1;31m'     # begin bold
export LESS_TERMCAP_md=$'\e[1;36m'     # begin blink
export LESS_TERMCAP_me=$'\e[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\e[01;44;33m' # begin reverse video
export LESS_TERMCAP_se=$'\e[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\e[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\e[0m'        # reset underline
export LESS='--ignore-case --LONG-PROMPT --RAW-CONTROL-CHARS --tabs=4 --window=4'
export BAT_PAGER="less $LESS"

# Add homebrew binaries to PATH
export PATH="/opt/homebrew/bin:$PATH"

# Add Wezterm CLI to PATH
export PATH="/Applications/WezTerm.app/Contents/MacOS:$PATH"

# Set GOROOT
export GOROOT="/opt/homebrew/opt/go/libexec"

# Add GOBIN to PATH
export PATH="$HOME/go/bin:$PATH"

# Add Cargo Bin to path.
export PATH="$HOME/.cargo/bin:$PATH"

# Use GCC
export PATH="/usr/homebrew/opt/gcc/bin:$PATH"

# Add NVM to PATH
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# Add Mason executables to PATH
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"

# GNU-time
export PATH="/opt/homebrew/opt/gnu-time/libexec/gnubin:$PATH"

# Use GNU-make: gmake as make
export PATH="/opt/homebrew/opt/make/libexec/gnubin:$PATH"

# Use brew M4
export PATH="/opt/homebrew/opt/m4/bin:$PATH"

# Boost libraries and headers location
export BOOST_ROOT="/opt/homebrew/Cellar"

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

# ============================== Alias Definitions ============================
# Use neo-vim by default
alias vim='nvim'

# Use bat instead of built-in cat
alias cat='bat'

# Use eza instead of ls
# alias ls='eza --grid --color=always --icons=always --long --git --no-filesize --no-time --no-user --no-permissions'
alias ls='eza --grid --color=always --icons=always'

# cd to Git Repository Project root
alias cdr='cd $(git rev-parse --show-toplevel)'

# Rosetta
alias rosetta="arch -x86_64"

# =============================================================================

# Forgot what was this for...
. "$HOME/.local/bin/env"

# Starship Prompt: https://starship.rs/
eval "$(starship init zsh)"

# OCaml (CS4212)
[[ ! -r "${HOME}/.opam/opam-init/init.zsh" ]] || source "${HOME}/.opam/opam-init/init.zsh" > /dev/null 2> /dev/null
eval $(opam env)

# zoxide - fast cd
export _ZO_DATA_DIR="$XDG_DATA_HOME"
eval "$(zoxide init zsh)"
