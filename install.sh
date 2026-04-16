#!/bin/bash
set -euo pipefail

# --- Colors (only if TTY) ---
if [[ -t 1 ]]; then
  Red='\033[0;31m'
  Green='\033[0;32m'
  Bold='\033[1m'
  Reset='\033[0m'
else
  Red='' Green='' Bold='' Reset=''
fi

info() { echo -e "${Green}bocek${Reset}: $*"; }
error() { echo -e "${Red}error${Reset}: $*" >&2; exit 1; }

# --- 1. Validate requirements ---
command -v git >/dev/null 2>&1 || error "git is required. Install git first."
command -v curl >/dev/null 2>&1 || error "curl is required."
command -v jq >/dev/null 2>&1 || error "jq is required. Install: brew install jq (mac) or apt install jq (linux)"

# --- 2. Create directory structure ---
BOCEK_HOME="$HOME/.bocek"
BIN_DIR="$BOCEK_HOME/bin"
SCRIPTS_DIR="$BOCEK_HOME/scripts"
PRIMITIVES_DIR="$BOCEK_HOME/primitives"

mkdir -p "$BIN_DIR" "$SCRIPTS_DIR"

# --- 3. Clone or update primitives ---
REPO_URL="https://github.com/patrickmvla/bocek.git"

if [ -d "$PRIMITIVES_DIR/.git" ]; then
  info "Primitives already installed, updating..."
  cd "$PRIMITIVES_DIR" && git pull --ff-only 2>/dev/null || info "Update failed, using existing primitives"
else
  info "Cloning primitives..."
  git clone --depth 1 "$REPO_URL" "$PRIMITIVES_DIR" || error "Failed to clone primitives"
fi

# --- 4. Copy toggle script ---
cp "$PRIMITIVES_DIR/scripts/bocek" "$BIN_DIR/bocek" || error "Failed to copy toggle script"

# --- 5. Copy enforcement script ---
cp "$PRIMITIVES_DIR/scripts/enforce-mode.sh" "$SCRIPTS_DIR/enforce-mode.sh" || error "Failed to copy enforcement script"

# --- 6. Set permissions ---
chmod +x "$BIN_DIR/bocek"
chmod +x "$SCRIPTS_DIR/enforce-mode.sh"

# --- 7. PATH configuration ---
if command -v bocek >/dev/null 2>&1; then
  info "bocek is already in PATH"
else
  SHELL_NAME=$(basename "$SHELL")
  EXPORT_LINE="export PATH=\"\$HOME/.bocek/bin:\$PATH\""
  COMMENT="# bocek"
  CONFIG=""

  case "$SHELL_NAME" in
    zsh)
      CONFIG="$HOME/.zshrc"
      ;;
    bash)
      if [ -f "$HOME/.bashrc" ]; then
        CONFIG="$HOME/.bashrc"
      elif [ -f "$HOME/.bash_profile" ]; then
        CONFIG="$HOME/.bash_profile"
      fi
      ;;
    fish)
      CONFIG="$HOME/.config/fish/config.fish"
      EXPORT_LINE="set -gx PATH \$HOME/.bocek/bin \$PATH"
      ;;
  esac

  if [ -n "$CONFIG" ] && [ -f "$CONFIG" ]; then
    # Check if already added (idempotent)
    if ! grep -q '\.bocek/bin' "$CONFIG" 2>/dev/null; then
      {
        echo ""
        echo "$COMMENT"
        echo "$EXPORT_LINE"
      } >> "$CONFIG"
      info "Added ~/.bocek/bin to PATH in $CONFIG"
    else
      info "PATH already configured in $CONFIG"
    fi
  else
    echo ""
    info "Add ~/.bocek/bin to your PATH manually:"
    echo "  $EXPORT_LINE"
    echo ""
  fi
fi

# --- 8. Confirmation ---
echo ""
info "Installation complete!"
echo ""
echo -e "  ${Bold}Next steps:${Reset}"
if [ -n "${CONFIG:-}" ]; then
  echo "  1. Open a new terminal (or run: source ${CONFIG})"
else
  echo "  1. Open a new terminal (or add ~/.bocek/bin to your PATH)"
fi
echo "  2. Navigate to a project: cd your-project"
echo "  3. Activate Bocek: bocek on"
echo "  4. Start Claude Code and load a primitive:"
echo "     \"Read ~/.bocek/primitives/design.md and follow it\""
echo ""
