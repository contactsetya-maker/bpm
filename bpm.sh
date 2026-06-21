#!/usr/bin/env bash

# ==============================================================================
# Unified Installation Script for bpm.sh (Bash Plugin Manager)
# ==============================================================================

set -euo pipefail

# Configuration Environment Defaults
TARGET_DIR="${BPM_DIR:-$HOME/.local/share/bpm}"
PLUGINS_DIR="$TARGET_DIR/plugins"
# Replace with your actual username/repository for remote deployment:
SCRIPT_URL="https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/bpm.sh"

# ANSI Terminal Coloring
RED='\033[0;31m'    GREEN='\033[0;32m'
YELLOW='\033[0;33m' BLUE='\033[0;34m'
BOLD='\033[1m'      NC='\033[0m'

_info()    { echo -e "${BLUE}${BOLD}[BPM-INSTALL]${NC} $1"; }
_success() { echo -e "${GREEN}${BOLD}[BPM-INSTALL]✓${NC} $1"; }
_warn()    { echo -e "${YELLOW}${BOLD}[BPM-INSTALL]!${NC} $1"; }
_error()   { echo -e "${RED}${BOLD}[BPM-INSTALL]✗ Error:${NC} $1" >&2; exit 1; }

# --- Pre-flight Dependency Analysis ---
_info "Analyzing environment capabilities..."
if ! command -v git &>/dev/null; then
    _error "git is an absolute runtime requirement. Please install git and retry."
fi

# Locate appropriate shell interactive profile
RC_FILE=""
if [[ -f "$HOME/.bashrc" ]]; then
    RC_FILE="$HOME/.bashrc"
elif [[ -f "$HOME/.bash_profile" ]]; then
    RC_FILE="$HOME/.bash_profile"
else
    _warn "Could not explicitly map standard shell profile locations (~/.bashrc or ~/.bash_profile)."
    read -rp "Please manually specify your target shell config path: " RC_FILE
fi

# --- Target Directory Generation ---
_info "Generating safe asset path routing at: $TARGET_DIR"
mkdir -p "$PLUGINS_DIR"

# --- Code Asset Resolution ---
if [[ "$SCRIPT_URL" != *"YOUR_USERNAME"* ]]; then
    _info "Fetching runtime platform from remote master cluster..."
    if ! curl -fsSL "$SCRIPT_URL" -o "$TARGET_DIR/bpm.sh"; then
        _error "Failed to cleanly stream remote codebase asset."
    fi
else
    # Development/Local Fallback
    if [[ -f "./bpm.sh" ]]; then
        _info "Deploying adjacent local developer platform asset to production runtime target..."
        cp "./bpm.sh" "$TARGET_DIR/bpm.sh"
    else
        _error "No local 'bpm.sh' found, and SCRIPT_URL has not been provisioned."
    fi
fi

chmod +x "$TARGET_DIR/bpm.sh"

# --- Shell Integration Injection Engine ---
_info "Configuring active execution layers inside: $RC_FILE"

BLOCK_MARKER="# === UNIFIED BPM CORE ARCHITECTURE BLOCK ==="
CONFIG_INJECTION=$(cat << 'EOF'
# === UNIFIED BPM CORE ARCHITECTURE BLOCK ===
bpm() {
    case "$1" in
        load)                 source "$HOME/.local/share/bpm/bpm.sh" "$@" ;;
        init-ble|finalize-ble) source "$HOME/.local/share/bpm/bpm.sh" "$1" ;;
        *)                    "$HOME/.local/share/bpm/bpm.sh" "$@" ;;
    esac
}

# 1. Bootstraps Ble.sh Line Editor hooks immediately (safe if not yet installed)
bpm init-ble

# --- [USER PLUGINS CONTAINER] ---
# bpm load "bash-users/bash-completion"
# --------------------------------

# 2. Closes and anchors the graphic input terminal interfaces
# This specific instruction MUST remain the final entry of your shell configuration
bpm finalize-ble

# Native Shell tab Auto-Completions
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
            local plugins; plugins=$(command ls "$HOME/.local/share/bpm/plugins" 2>/dev/null)
            COMPREPLY=( $(compgen -W "$plugins" -- "$cur") )
            return 0 ;;
    esac
    [[ $COMP_CWORD -eq 1 ]] && COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}
complete -F _bpm_completion bpm
# ============================================
EOF
)

# Atomic matching validation to maintain single instance blocks
if grep -qF "$BLOCK_MARKER" "$RC_FILE" 2>/dev/null; then
    _warn "An active bpm architecture block was already recognized inside $RC_FILE."
    _info "Skipping auto-injection to guard existing custom configurations."
else
    echo -e "\n$CONFIG_INJECTION" >> "$RC_FILE"
    _success "Successfully linked unified manager environment."
fi

# --- Compilation Output Block ---
echo -e "\n----------------------------------------------------------------"
_success "${BOLD}The Unified Bash Plugin Manager is ready!${NC}"
_info "Initialize your shell context to begin using bpm:"
echo -e "  ${BOLD}source $RC_FILE${NC}"
echo -e "----------------------------------------------------------------\n"
