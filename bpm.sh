#!/usr/bin/env bash

# ==============================================================================
# bpm.sh - High-Performance, Unified Bash Plugin Manager
# ==============================================================================

set -euo pipefail

# Configuration
BPM_DIR="${BPM_DIR:-$HOME/.local/share/bpm}"
BPM_PLUGINS_DIR="$BPM_DIR/plugins"
mkdir -p "$BPM_PLUGINS_DIR"

# Formatting Colors
RED='\033[0;31m'    GREEN='\033[0;32m'
YELLOW='\033[0;33m' BLUE='\033[0;34m'
BOLD='\033[1m'      NC='\033[0m'

_info()    { echo -e "${BLUE}${BOLD}[BPM]${NC} $1"; }
_success() { echo -e "${GREEN}${BOLD}[BPM]✓${NC} $1"; }
_warn()    { echo -e "${YELLOW}${BOLD}[BPM]!${NC} $1"; }
_error()   { echo -e "${RED}${BOLD}[BPM]✗ Error:${NC} $1" >&2; }

_usage() {
    cat << EOF
bpm.sh - Advanced Bash Plugin Manager

Usage:
  bpm.sh load <repo> [options]  - Install and source a plugin
  bpm.sh init-ble               - Pre-initialize ble.sh (if installed)
  bpm.sh finalize-ble           - Attach ble.sh terminal engine
  bpm.sh update [<repo>]        - Update plugins in parallel (or a specific repo)
  bpm.sh list                   - List active plugins and versions
  bpm.sh clean                  - Prune unused files and optimize repositories
  bpm.sh ui                     - Launch interactive management dashboard
  bpm.sh self-update            - Upgrade bpm.sh framework to the latest version

Options for 'load':
  --use <filename>              - Explicitly target this file to source
  --on <command>                - Run a post-install compilation hook
  --branch <name>               - Target a specific branch, tag, or commit
EOF
}

# --- Helper Functions ---

_get_plugin_dir() {
    local repo="$1"
    if [[ "$repo" == /* || "$repo" == .* ]]; then
        realpath "$repo"
    else
        echo "$BPM_PLUGINS_DIR/${repo#*/}"
    fi
}

_find_entry_point() {
    local dir="$1" custom_use="$2"
    if [[ -n "$custom_use" && -f "$dir/$custom_use" ]]; then
        echo "$dir/$custom_use"; return
    fi
    
    local name; name=$(basename "$dir")
    local candidates=(
        "$dir/$name.plugin.bash" "$dir/$name.bash" "$dir/$name.sh" 
        "$dir/init.bash" "$dir/init.sh" "$dir/plugin.bash"
    )
    for c in "${candidates[@]}"; do
        [[ -f "$c" ]] && { echo "$c"; return; }
    done
    find "$dir" -maxdepth 1 \( -name "*.plugin.bash" -o -name "*.bash" -o -name "*.sh" \) -print -quit
}

# --- Core Commands ---

bpm_load() {
    local repo="" use_file="" hook="" branch=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --use)    use_file="$2"; shift 2 ;;
            --on)     hook="$2";     shift 2 ;;
            --branch) branch="$2";   shift 2 ;;
            -*)       _error "Unknown option $1"; return 1 ;;
            *)        repo="$1";     shift ;;
        esac
    done

    [[ -z "$repo" ]] && { _error "No repository specified."; return 1; }
    
    local dest; dest=$(_get_plugin_dir "$repo")

    # Clone repository if it doesn't exist locally
    if [[ ! -d "$dest" ]]; then
        _info "Cloning $repo..."
        local branch_flag=()
        [[ -n "$branch" ]] && branch_flag=(--branch "$branch")
        
        if ! git clone --depth 1 "${branch_flag[@]}" "https://github.com/$repo.git" "$dest" &>/dev/null; then
            _error "Failed cloning $repo"
            return 1
        fi
        
        if [[ -n "$hook" ]]; then
            _info "Running post-install hook for $repo..."
            (cd "$dest" && eval "$hook") || _warn "Hook failed for $repo"
        fi
        _success "Loaded $repo"
    fi

    # Source into environment safely
    local entry; entry=$(_find_entry_point "$dest" "$use_file")
    if [[ -n "$entry" ]]; then
        source "$entry" || _warn "Failed sourcing $entry"
    else
        _warn "Could not resolve valid shell entry file in $repo"
    fi
}

bpm_ensure_blesh() {
    local ble_dir="$BPM_PLUGINS_DIR/ble.sh"
    
    if [[ ! -d "$ble_dir" ]]; then
        _info "Installing ble.sh (compiling framework, please wait)..."
        local tmp_clone; tmp_clone=$(mktemp -d)
        if git clone --depth 1 --recursive https://github.com/akinomyoga/ble.sh.git "$tmp_clone" &>/dev/null; then
            (cd "$tmp_clone" && make &>/dev/null && make install INSDIR="$ble_dir" &>/dev/null)
            _success "ble.sh compiled successfully."
        else
            _error "Failed to clone ble.sh repository."
        fi
        rm -rf "$tmp_clone"
    fi

    [[ $- != *i* ]] && return # Exit if shell is non-interactive
    if [[ -f "$ble_dir/share/ble/ble.sh" ]] && ! type ble-attach &>/dev/null; then
        source "$ble_dir/share/ble/ble.sh" --noattach
    fi
}

bpm_finalize_ble() {
    if type ble-attach &>/dev/null; then
        ble-attach
    fi
}

bpm_update() {
    local target="${1:-}"
    
    _update_dir() {
        local dir="$1"
        (
            cd "$dir"
            local old_rev; old_rev=$(git rev-parse HEAD)
            git fetch --depth 1 origin &>/dev/null
            git reset --hard origin/$(git branch --show-current 2>/dev/null || echo "main") &>/dev/null
            if [[ "$old_rev" != "$(git rev-parse HEAD)" ]]; then
                echo -e "${GREEN}Updated $(basename "$dir")${NC}"
            fi
        )
    }

    if [[ -n "$target" ]]; then
        local dest; dest=$(_get_plugin_dir "$target")
        [[ -d "$dest/.git" ]] && _update_dir "$dest" || _error "Plugin '$target' not found or not a git repo."
    else
        _info "Updating all plugins concurrently..."
        local pids=()
        for d in "$BPM_PLUGINS_DIR"/*; do
            if [[ -d "$d" && -d "$d/.git" ]]; then
                _update_dir "$d" & pids+=($!)
            fi
        done
        for pid in "${pids[@]}"; do wait "$pid"; done
        _success "All updates completed."
    fi
}

bpm_clean() {
    _info "Optimizing plugins and clearing garbage..."
    for d in "$BPM_PLUGINS_DIR"/*; do
        if [[ -d "$d/.git" ]]; then
            git -C "$d" gc --prune=now &>/dev/null &
        fi
    done
    wait
    _success "Optimization complete."
}

bpm_list() {
    echo -e "${BOLD}Managed Plugins:${NC}"
    for d in "$BPM_PLUGINS_DIR"/*; do
        if [[ -d "$d" ]]; then
            local branch; branch=$(git -C "$d" branch --show-current 2>/dev/null || echo "local/custom")
            echo -e "  ${BLUE}*${NC} $(basename "$d") [branch: $branch]"
        fi
    done
}

bpm_ui() {
    if ! command -v dialog &>/dev/null; then
        _warn "'dialog' utility not found. Falling back to clean shell-select prompt..."
        echo -e "${BOLD}Select a plugin to remove (or 'q' to quit):${NC}"
        select opt in $(command ls "$BPM_PLUGINS_DIR"); do
            [[ "$opt" == "q" || -z "$opt" ]] && break
            read -rp "Uninstall $opt? (y/N): " confirm
            [[ "$confirm" =~ ^[Yy]$ ]] && rm -rf "$BPM_PLUGINS_DIR/$opt" && _success "Removed $opt"
            break
        done
        return
    fi

    local tempfile; tempfile=$(mktemp)
    local choices=()
    for d in "$BPM_PLUGINS_DIR"/*; do
        [[ -d "$d" ]] && choices+=("$(basename "$d")" "Plugin Active" "ON")
    done

    if [[ ${#choices[@]} -eq 0 ]]; then
        dialog --title " BPM " --msgbox "No active plugins installed." 6 40
        return
    fi

    if dialog --title " Interactive BPM Engine " --checklist "Spacebar to uncheck/delete. Enter to execute:" 15 50 8 "${choices[@]}" 2> "$tempfile"; then
        local selected; selected=$(cat "$tempfile")
        for d in "$BPM_PLUGINS_DIR"/*; do
            if [[ -d "$d" ]]; then
                local name; name=$(basename "$d")
                if [[ "$selected" != *"$name"* ]]; then
                    rm -rf "$d" && _info "Pruned $name"
                fi
            fi
        done
        _success "Modifications successfully synced."
    fi
    rm -f "$tempfile"; clear
}

bpm_self_update() {
    _info "Reaching out for raw core updates..."
    local remote_url="https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/bpm.sh"
    local tmp; tmp=$(mktemp)
    if curl -fsSL "$remote_url" -o "$tmp" && grep -q "BPM_PLUGINS_DIR" "$tmp"; then
        cp "$tmp" "$BPM_DIR/bpm.sh" && chmod +x "$BPM_DIR/bpm.sh"
        _success "bpm.sh platform upgraded flawlessly."
    else
        _error "Core verification down or invalid endpoint asset."
    fi
    rm -f "$tmp"
}

# --- Execution Router ---
case "${1:-}" in
    load)         shift; bpm_load "$@" ;;
    init-ble)     bpm_ensure_blesh ;;
    finalize-ble) bpm_finalize_ble ;;
    update)       shift; bpm_update "${1:-}" ;;
    list)         bpm_list ;;
    clean)        bpm_clean ;;
    ui)           bpm_ui ;;
    self-update)  bpm_self_update ;;
    *)            _usage ;;
esac
