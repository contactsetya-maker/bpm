#!/usr/bin/env bash

# ==============================================================================
# build.sh - High-Performance Native Compilation Tool for bpm-c
# ==============================================================================

set -euo pipefail

# Formatting Colors
RED='\033[0;31m'    GREEN='\033[0;32m'
YELLOW='\033[0;33m' BLUE='\033[0;34m'
BOLD='\033[1m'      NC='\033[0m'

_info()    { echo -e "${BLUE}${BOLD}[BUILD]${NC} $1"; }
_success() { echo -e "${GREEN}${BOLD}[BUILD]✓${NC} $1"; }
_warn()    { echo -e "${YELLOW}${BOLD}[BUILD]!${NC} $1"; }
_error()   { echo -e "${RED}${BOLD}[BUILD]✗ Error:${NC} $1" >&2; }

# Configuration
SOURCE_FILE="bpm.c"
OUTPUT_BINARY="bpm"
INSTALL_DIR="${HOME}/.local/bin"

# Default Build Flags (Production-grade Performance)
CFLAGS="-O3 -Wall -Wextra -pedantic -std=c11"

# Parse Flags
DEBUG_MODE=false
for arg in "$@"; do
    case "$arg" in
        --debug)
            DEBUG_MODE=true
            CFLAGS="-O0 -g -Wall -Wextra -std=c11 -DDEBUG"
            ;;
        --help|-h)
            echo "Usage: ./build.sh [--debug]"
            echo "  --debug    Compile with debug symbols and no optimization"
            exit 0
            ;;
    esac
done

# --- 1. Pre-flight Checks ---

if [[ ! -f "$SOURCE_FILE" ]]; then
    _error "Source file '$SOURCE_FILE' not found in the current directory."
    exit 1
fi

# Detect Compiler (Prefer clang over gcc if available for better diagnostic messaging)
if command -v clang &>/dev/null; then
    COMPILER="clang"
elif command -v gcc &>/dev/null; then
    COMPILER="gcc"
else
    _error "No valid C compiler (gcc or clang) found in PATH."
    exit 1
fi

# --- 2. Compilation Phase ---

if [ "$DEBUG_MODE" = true ]; then
    _info "Compiling ${OUTPUT_BINARY} in ${BOLD}DEBUG${NC} mode using ${COMPILER}..."
else
    _info "Compiling ${OUTPUT_BINARY} in ${BOLD}PRODUCTION (Optimized)${NC} mode using ${COMPILER}..."
fi

# Execute compilation string
if $COMPILER $CFLAGS "$SOURCE_FILE" -o "$OUTPUT_BINARY"; then
    _success "Compilation successful: ./${OUTPUT_BINARY}"
else
    _error "Compilation failed."
    exit 1
fi

# --- 3. Installation Phase ---

mkdir -p "$INSTALL_DIR"

_info "Installing binary to ${INSTALL_DIR}..."
if cp "$OUTPUT_BINARY" "$INSTALL_DIR/$OUTPUT_BINARY" && chmod +x "$INSTALL_DIR/$OUTPUT_BINARY"; then
    _success "Binary deployed successfully."
else
    _error "Failed to copy binary to ${INSTALL_DIR}."
    exit 1
fi

# --- 4. Final Shell Integrity Verification ---

echo -e "\n--- Setup Verification ---"
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    _warn "${INSTALL_DIR} is not in your current system PATH."
    echo -e "To fix this, add the following line to your ${BOLD}~/.bashrc${NC}:"
    echo -e "  ${BLUE}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
fi

_success "Build workflow complete!"
