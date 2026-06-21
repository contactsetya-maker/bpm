# ==============================================================================
# ~/.bash_aliases - Modern Tool Integrations & Custom Shortcuts
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Zoxide Initialization (Smarter cd)
# ------------------------------------------------------------------------------
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
    alias cd="z"
fi

# ------------------------------------------------------------------------------
# 2. Eza Configurations (Modern replacement for ls)
# ------------------------------------------------------------------------------
if command -v eza &>/dev/null; then
    # Standard overrides
    alias ls="eza --icons --group-directories-first"
    alias ll="eza -lbF --icons --git --group-directories-first"
    alias la="eza -lbaiF --icons --git --group-directories-first"
    alias l="eza -lbF --icons --git --group-directories-first"
    
    # Custom layouts
    alias lt="eza --tree --level=2 --icons"       # 2-level directory tree
    alias lx="eza -lbHHigUmuSa@ --icons --git"    # Maximum metadata view
else
    # Fallbacks if eza isn't present on the host system
    alias ll="ls -alF"
    alias la="ls -A"
    alias l="ls -CF"
fi

# ------------------------------------------------------------------------------
# 3. Aptitude Package Management Shortcuts
# ------------------------------------------------------------------------------
if command -v aptitude &>/dev/null; then
    alias apti="sudo aptitude"
    alias apti-search="aptitude search"
    alias apti-show="aptitude show"
    alias apti-install="sudo aptitude install"
    alias apti-upgrade="sudo aptitude safe-upgrade"
    alias apti-clean="sudo aptitude clean && sudo aptitude autoclean"
fi

# ------------------------------------------------------------------------------
# 4. Core Navigation & Quality of Life
# ------------------------------------------------------------------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias grep="grep --color=auto"
alias diff="diff --color=auto"
