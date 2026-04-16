# Install Script: Design

## Context
The install script is the user's first interaction with Bocek. It must work on a single `curl | bash` invocation, require no dependencies beyond git and curl, and leave the user ready to run `bocek on` in any project.

## Goals
- Single command installation: `curl -fsSL bocek.dev/install | bash`
- No dependencies beyond git, curl, and jq
- Detect platform, shell, and configure PATH automatically
- Idempotent — running twice doesn't break anything
- Clean uninstall path — `rm -rf ~/.bocek` removes everything

## Non-Goals
- Not a package manager — no versioning of installed primitives beyond git
- Not a project initializer — `bocek on` handles per-project setup
- Not a Windows installer — WSL is the supported Windows path

## Design

### Installation flow

```
1. Validate requirements (git, curl, jq)
   ↓
2. Create ~/.bocek/ directory structure
   ↓
3. Clone primitives repo to ~/.bocek/primitives/
   ↓
4. Copy toggle script to ~/.bocek/bin/bocek
   ↓
5. Copy enforcement script to ~/.bocek/scripts/enforce-mode.sh
   ↓
6. Set executable permissions
   ↓
7. Check if bocek is already in PATH
   ├─ YES → Skip shell configuration
   └─ NO → Detect shell, modify profile
        ├─ zsh → append to ~/.zshrc
        ├─ bash → append to ~/.bashrc or ~/.bash_profile
        ├─ fish → append to ~/.config/fish/config.fish
        └─ other → print manual instructions
   ↓
8. Print confirmation and next steps
```

### Script outline

```bash
#!/bin/bash
set -euo pipefail

# --- Colors (only if TTY) ---
if [[ -t 1 ]]; then
  Red='\033[0;31m'
  Green='\033[0;32m'
  Dim='\033[0;2m'
  Bold='\033[1m'
  Reset='\033[0m'
else
  Red='' Green='' Dim='' Bold='' Reset=''
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
REPO_URL="https://github.com/bocek-dev/bocek.git"  # TBD: actual repo URL

if [ -d "$PRIMITIVES_DIR/.git" ]; then
  info "Primitives already installed, updating..."
  cd "$PRIMITIVES_DIR" && git pull --ff-only 2>/dev/null || info "Update failed, using existing primitives"
else
  info "Cloning primitives..."
  git clone --depth 1 "$REPO_URL" "$PRIMITIVES_DIR" || error "Failed to clone primitives"
fi

# --- 4. Copy toggle script ---
# The toggle script lives in the primitives repo at scripts/bocek
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

  case "$SHELL_NAME" in
    zsh)
      CONFIG="$HOME/.zshrc"
      ;;
    bash)
      # Prefer .bashrc, fall back to .bash_profile
      if [ -w "$HOME/.bashrc" ]; then
        CONFIG="$HOME/.bashrc"
      elif [ -w "$HOME/.bash_profile" ]; then
        CONFIG="$HOME/.bash_profile"
      else
        CONFIG=""
      fi
      ;;
    fish)
      CONFIG="$HOME/.config/fish/config.fish"
      EXPORT_LINE="set -gx PATH \$HOME/.bocek/bin \$PATH"
      ;;
    *)
      CONFIG=""
      ;;
  esac

  if [ -n "$CONFIG" ] && [ -w "$CONFIG" ]; then
    # Check if already added (idempotent)
    if ! grep -q "\.bocek/bin" "$CONFIG" 2>/dev/null; then
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
echo "  ${Bold}Next steps:${Reset}"
echo "  1. Open a new terminal (or run: source ~/${CONFIG##*/})"
echo "  2. Navigate to a project: cd your-project"
echo "  3. Activate Bocek: bocek on"
echo "  4. Start Claude Code and load a primitive:"
echo "     \"Read ~/.bocek/primitives/design.md and follow it\""
echo ""
```

### What the install script does NOT do

- Does NOT run `bocek on` — per-project activation is the user's decision
- Does NOT create any per-project files — no `.bocek/` directory in any project
- Does NOT modify any Claude Code settings — `bocek on` handles that
- Does NOT require sudo — everything lives in `$HOME`

### Uninstallation

```bash
# Complete removal
rm -rf ~/.bocek

# Remove PATH entry from shell config (manual)
# Delete the "# bocek" and export line from ~/.zshrc or ~/.bashrc
```

A future `bocek uninstall` command could automate this, but for v1, manual removal is documented and sufficient.

### Update mechanism

`bocek update` runs `git pull --ff-only` in `~/.bocek/primitives/` and re-copies the toggle and enforcement scripts. This ensures the scripts stay in sync with the primitives repo.

```bash
# bocek update flow
cd ~/.bocek/primitives
git pull --ff-only
cp scripts/bocek ~/.bocek/bin/bocek
cp scripts/enforce-mode.sh ~/.bocek/scripts/enforce-mode.sh
chmod +x ~/.bocek/bin/bocek
chmod +x ~/.bocek/scripts/enforce-mode.sh
```

### Security considerations

- The install script is served over HTTPS from `bocek.dev`
- `curl -fsSL` fails on non-2xx responses and follows redirects over HTTPS
- The primitives repo is cloned from GitHub over HTTPS
- No code is executed from the cloned repo during installation — only files are copied
- Users can inspect the install script before running: `curl -fsSL bocek.dev/install | less`

## Trade-offs

**Shell profile modification vs manual setup:** Auto-modification is invasive but expected. Every major CLI tool (Bun, Rust, Deno) does it. The alternative (manual PATH setup) causes "command not found" frustration that kills adoption. The script checks before appending and never duplicates.

**`curl | bash` vs package manager:** `curl | bash` is controversial but universal. It works on every platform without package manager dependencies. The alternative (npm, brew, apt) requires managing packages across registries. For a tool that's "just bash scripts and markdown files," a package manager is overkill.

**Single repo for everything:** Primitives, scripts, and the install script all live in one repo. This simplifies installation and updates but means the toggle script and enforcement script are versioned with the primitives. Accepted because they should evolve together.

## References
- ADR-0020: Install follows Bun's pattern
- Bun install script: https://bun.sh/install
- Claude Code setup docs: https://code.claude.com/docs/en/setup
