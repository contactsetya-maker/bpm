# 🚀 bpm - High-Performance Bash Plugin Manager

`bpm` is a minimalist, blazing-fast, and zero-dependency plugin manager for Bash. It features parallel updates, post-install compilation hooks, a lightweight interactive TUI, tab auto-completion, and native, first-class integration for **`ble.sh`** (Bash Line Editor).

Built entirely in pure Bash, `bpm` keeps your shell environment clean, modular, and reproducible.

---

## ✨ Features

- ⚡ **Parallel Execution:** Updates all of your managed plugins concurrently to save bandwidth and time.
- 🎨 **First-Class `ble.sh` Support:** Seamlessly handles the early-init and late-attach requirements of `ble.sh` without breaking standard plugin sourcing.
- 🎛️ **Interactive TUI Dashboard:** Manage, view, and prune your shell plugins using an optional `dialog`-driven interface (`bpm ui`).
- 🧠 **Smart Sourcing Heuristics:** Automatically detects common entry points (`*.plugin.bash`, `init.bash`, `*.sh`) so most community plugins just work out of the box.
- ⚙️ **Advanced Directives:** Supports explicit file targets (`--use`), post-install build hooks (`--on`), and specific branch/tag pinning (`--branch`).
- 🛠️ **Native Auto-Completion:** Full tab-completion support for commands, flags, and installed repository names.

---

## 📦 Installation

You can install `bpm` instantly with the following one-liner:

```bash
curl -sSL [https://raw.githubusercontent.com/contactsetya-maker/bpm/main/install.sh](https://raw.githubusercontent.com/contactsetya-maker/bpm/main/install.sh) | bash
