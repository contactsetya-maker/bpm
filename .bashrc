# ==============================================================================
# ~/.bashrc - Unified Shell Architecture
# ==============================================================================

# --- Standard Interactive Shell Sanity Checks ---
# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Shell Options
shopt -s histappend checkwinsize globstar 2>/dev/null

# History Configurations
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups

# ------------------------------------------------------------------------------
# 1. BPM Core Configuration & Engine Setup
# ------------------------------------------------------------------------------
export BPM_DIR="$HOME/.local/share/bpm"

bpm() {
    case "$1" in
        load)                 source "$BPM_DIR/bpm.sh" "$@" ;;
        init-ble|finalize-ble) source "$BPM_DIR/bpm.sh" "$1" ;;
        *)                    "$BPM_DIR/bpm.sh" "$@" ;;
    esac
}

# ------------------------------------------------------------------------------
# 2. Stage 1 Init: Bootstrap Interactive Hook Engines
# ------------------------------------------------------------------------------
# Pre-initializes ble.sh mechanics smoothly before loading plugins
bpm init-ble

# ------------------------------------------------------------------------------
# 3. Stage 2 Loading: Core Community Extensions & Tooling
# ------------------------------------------------------------------------------
# Standard completions
bpm load "bash-users/bash-completion"

# Advanced plugin integrations
bpm load "junegunn/fzf" --use "shell/completion.bash"
bpm load "junegunn/fzf" --use "shell/key-bindings.bash"

# ------------------------------------------------------------------------------
# 4. Stage 3 Loading: Local Configs, Modern Tooling & Aliases
# ------------------------------------------------------------------------------
# Load your custom standalone aliases file natively through the engine
if [[ -f "$HOME/.bash_aliases" ]]; then
    bpm load "$HOME/.bash_aliases"
fi

# ------------------------------------------------------------------------------
# 5. Stage 4 Finalize: Mount Visual Rendering Layers
# ------------------------------------------------------------------------------
# Attaches the graphics prompt layout and binds all hotkeys/syntaxes.
# CRITICAL: This MUST remain the absolute last directive in your configuration!
bpm finalize-ble

# ------------------------------------------------------------------------------
# 6. Native Shell Auto-Completions Framework
# ------------------------------------------------------------------------------
_bpm_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="load update list clean ui self-update help"

    case "$prev" in
        load)
            [[ "$cur" == -* ]] && COMPREPLY=( $(compgen -W "--use --on --branch" -- "$cur") )
            return 0 ;;
        update)
            local plugins; plugins=$(command ls "$BPM_DIR/plugins" 2>/dev/null)
            COMPREPLY=( $(compgen -W "$plugins" -- "$cur") )
            return 0 ;;
    esac
    [[ $COMP_CWORD -eq 1 ]] && COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}
complete -F _bpm_completion bpm
