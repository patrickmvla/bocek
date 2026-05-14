#!/bin/bash
# Bocek preflight — orientation block emitted before a primitive activates.
# Usage: bash ~/.bocek/scripts/preflight.sh <mode>
#
# Side effect: writes <mode> to .bocek/mode so the enforce-mode hook activates immediately.
#
# Output is plain text designed to be read by the model as it loads the primitive.

set -euo pipefail

MODE="${1:-idle}"

# --- Validate mode ---
case "$MODE" in
  design|research|implementation|debugging|refactoring|review|idle) ;;
  *)
    echo "preflight: unknown mode '$MODE' (expected: design|research|implementation|debugging|refactoring|review|idle)" >&2
    exit 1
    ;;
esac

# --- Project root: walk up for .bocek/, then git root, then start dir ---
# Walk-up handles invocation from any subdir (e.g. .bocek/vault/) without doubling the path.
find_project_root() {
  local start="$1"
  local dir="$start"
  while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    # Skip descendants of another .bocek/ — likely cruft from the path-doubling bug.
    case "$dir" in
      */.bocek/*) dir=$(dirname "$dir"); continue ;;
    esac
    if [ -d "$dir/.bocek" ]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  local git_root
  git_root=$(git -C "$start" rev-parse --show-toplevel 2>/dev/null || true)
  if [ -n "$git_root" ]; then
    printf '%s\n' "$git_root"
    return 0
  fi
  printf '%s\n' "$start"
}

PROJECT_ROOT=$(find_project_root "${CLAUDE_PROJECT_DIR:-$PWD}")

# --- 0. Capture previous mode, then write current mode BEFORE any stdout echo. ---
# Per [[preflight-sigpipe-fix]]: the mode-write side effect must complete before any
# echo, so that stdout truncation by the caller (e.g. `| head -8`) under
# `set -euo pipefail` cannot SIGPIPE-abort the script before the write executes.
MODE_FILE="$PROJECT_ROOT/.bocek/mode"
PREVIOUS_MODE=""
if [ -f "$MODE_FILE" ]; then
  PREVIOUS_MODE=$(<"$MODE_FILE")
  PREVIOUS_MODE="${PREVIOUS_MODE//[[:space:]]/}"
fi
mkdir -p "$PROJECT_ROOT/.bocek"
echo "$MODE" > "$MODE_FILE"
# Read back — silent failure here would let the enforcement hook read a stale mode.
WRITTEN=$(<"$MODE_FILE")
WRITTEN="${WRITTEN//[[:space:]]/}"
if [ "$WRITTEN" != "$MODE" ]; then
  echo "preflight: mode write to $MODE_FILE did not take (expected '$MODE', got '$WRITTEN')" >&2
  exit 1
fi

echo "=== Bocek Preflight — ${MODE} ==="

# --- 1. Mode transition (display only — write already happened in section 0) ---
if [ -z "$PREVIOUS_MODE" ]; then
  echo "Mode: (no prior) → $MODE"
elif [ "$PREVIOUS_MODE" = "$MODE" ]; then
  echo "Mode: $MODE (unchanged)"
else
  echo "Mode: $PREVIOUS_MODE → $MODE"
fi

# --- 2. Last checkpoint ---
STATE_FILE="$PROJECT_ROOT/.bocek/state.md"
if [ -f "$STATE_FILE" ]; then
  echo ""
  echo "Last checkpoint (.bocek/state.md):"
  head -8 "$STATE_FILE" | sed 's/^/  /'
  TOTAL_LINES=$(wc -l < "$STATE_FILE" | tr -d ' ')
  if [ "$TOTAL_LINES" -gt 8 ]; then
    echo "  ... ($((TOTAL_LINES - 8)) more lines — read the file in full if you need continuity)"
  fi
fi

# --- 3. Vault state ---
VAULT_DIR="$PROJECT_ROOT/.bocek/vault"
ENTRY_COUNT=0
if [ -d "$VAULT_DIR" ]; then
  ENTRY_COUNT=$(find "$VAULT_DIR" -maxdepth 4 -name "*.md" -not -name "index.md" -not -name "CONTEXT.md" 2>/dev/null | wc -l | tr -d ' ')
  echo ""
  echo "Vault: $ENTRY_COUNT entries at $VAULT_DIR"
  if [ -f "$VAULT_DIR/index.md" ]; then
    echo "  index.md present — read it for the entry map"
  else
    echo "  no index.md — create one when first entry is written"
  fi
  if [ -f "$VAULT_DIR/CONTEXT.md" ]; then
    echo "  CONTEXT.md present — project-domain vocabulary, read on every primitive activation"
  else
    echo "  no CONTEXT.md — create one to capture project-specific vocabulary (see [[context-md-as-vocabulary]])"
  fi
  # Feature folders (per Path convention: vault/{feature}/{slug}.md)
  FEATURE_DIRS=$(find "$VAULT_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" 2>/dev/null | sort)
  if [ -n "$FEATURE_DIRS" ]; then
    echo "  feature folders:"
    while IFS= read -r fd; do
      [ -z "$fd" ] && continue
      # Count entries directly in feature folder (depth 2 from vault root)
      direct=$(find "$VAULT_DIR/$fd" -mindepth 1 -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
      # Count .research/ entries inside the feature folder (depth 3 from vault root)
      research=$(find "$VAULT_DIR/$fd/.research" -mindepth 1 -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
      if [ "$research" -gt 0 ]; then
        printf '    %s/ (%s; +%s in .research)\n' "$fd" "$direct" "$research"
      else
        printf '    %s/ (%s)\n' "$fd" "$direct"
      fi
    done <<< "$FEATURE_DIRS"
  fi
  # Loose entries directly in vault/ (path-convention violation — flag for cleanup)
  LOOSE=$(find "$VAULT_DIR" -mindepth 1 -maxdepth 1 -type f -name "*.md" -not -name "index.md" -printf "%f\n" 2>/dev/null | sort)
  if [ -n "$LOOSE" ]; then
    echo "  ⚠ loose entries (should be in {feature}/ folders per vault path convention):"
    printf '    %s\n' $LOOSE
  fi
  # Recent entries across all feature folders (depth 2: direct entries; depth 3: .research/ entries)
  RECENT=$(find "$VAULT_DIR" -mindepth 2 -maxdepth 3 -type f -name "*.md" -printf "%T@ %P\n" 2>/dev/null | sort -rn | head -5 | awk '{print $2}')
  if [ -n "$RECENT" ]; then
    echo "  recent entries:"
    printf '    %s\n' $RECENT
  fi
else
  echo ""
  echo "Vault: not initialized (will be created at $VAULT_DIR on first write)"
fi

# --- 4. Project domain signals ---
echo ""
echo "Project signals:"
DOMAIN_HINTS=()
IDIOM_HINTS=()
SIGNALS_FOUND=0

# TypeScript signal — tsconfig.json (works even without package.json)
if [ -f "$PROJECT_ROOT/tsconfig.json" ]; then
  SIGNALS_FOUND=1
  echo "  language: typescript"
  IDIOM_HINTS+=("typescript")
fi

# package.json — grep cheaply for known libraries
if [ -f "$PROJECT_ROOT/package.json" ]; then
  SIGNALS_FOUND=1
  grep_pkg() { grep -oE "\"($1)\"" "$PROJECT_ROOT/package.json" 2>/dev/null | tr -d '"' | sort -u | paste -sd, - || true; }

  # TypeScript via package.json (only echo once)
  if [ ! -f "$PROJECT_ROOT/tsconfig.json" ] && grep -qE '"typescript"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
    echo "  language: typescript"
    IDIOM_HINTS+=("typescript")
  fi

  FRONTEND=$(grep_pkg 'react|next|vue|svelte|nuxt|astro|remix|solid|expo|react-native|preact|qwik')
  if [ -n "$FRONTEND" ]; then
    echo "  frontend: $FRONTEND"
    DOMAIN_HINTS+=("frontend")
  fi

  AUTH=$(grep_pkg 'passport|next-auth|@auth/[a-z-]+|clerk|@clerk/[a-z-]+|auth0|firebase-auth|better-auth|lucia|@supabase/auth-helpers|iron-session')
  if [ -n "$AUTH" ]; then
    echo "  auth: $AUTH"
    DOMAIN_HINTS+=("auth")
  fi

  DATA=$(grep_pkg 'prisma|drizzle-orm|typeorm|sequelize|mongoose|kysely|pg|mysql2|better-sqlite3|@planetscale/database|@neondatabase/serverless')
  if [ -n "$DATA" ]; then
    echo "  data layer: $DATA"
    DOMAIN_HINTS+=("data-layer")
  fi

  STATE=$(grep_pkg 'redux|@reduxjs/toolkit|zustand|jotai|recoil|mobx|@tanstack/query|@tanstack/react-query|swr|valtio|nanostores')
  if [ -n "$STATE" ]; then
    echo "  state mgmt: $STATE"
    DOMAIN_HINTS+=("state-management")
  fi

  API=$(grep_pkg 'express|fastify|hono|koa|@nestjs/core|@trpc/server|graphql|apollo-server|@apollo/server')
  if [ -n "$API" ]; then
    echo "  api layer: $API"
    DOMAIN_HINTS+=("api-design")
  fi
fi

# Go module
if [ -f "$PROJECT_ROOT/go.mod" ]; then
  SIGNALS_FOUND=1
  GO_MOD_NAME=$(awk '/^module /{print $2; exit}' "$PROJECT_ROOT/go.mod")
  echo "  go.mod: $GO_MOD_NAME"
  if grep -qE 'gin-gonic/gin|labstack/echo|gofiber/fiber|go-chi/chi|gorilla/mux' "$PROJECT_ROOT/go.mod" 2>/dev/null; then
    DOMAIN_HINTS+=("api-design")
  fi
  if grep -qE 'jmoiron/sqlx|gorm.io/gorm|ent/ent|uptrace/bun|jackc/pgx' "$PROJECT_ROOT/go.mod" 2>/dev/null; then
    DOMAIN_HINTS+=("data-layer")
  fi
fi

# Rust
if [ -f "$PROJECT_ROOT/Cargo.toml" ]; then
  SIGNALS_FOUND=1
  CRATE_NAME=$(awk -F'"' '/^name/{print $2; exit}' "$PROJECT_ROOT/Cargo.toml")
  echo "  Cargo.toml: $CRATE_NAME"
  if grep -qE '^(axum|actix-web|rocket|warp|hyper) *=' "$PROJECT_ROOT/Cargo.toml" 2>/dev/null; then
    DOMAIN_HINTS+=("api-design")
  fi
  if grep -qE '^(sqlx|diesel|sea-orm) *=' "$PROJECT_ROOT/Cargo.toml" 2>/dev/null; then
    DOMAIN_HINTS+=("data-layer")
  fi
fi

# Python
if [ -f "$PROJECT_ROOT/pyproject.toml" ] || [ -f "$PROJECT_ROOT/requirements.txt" ] || [ -f "$PROJECT_ROOT/setup.py" ]; then
  SIGNALS_FOUND=1
  if [ -f "$PROJECT_ROOT/pyproject.toml" ]; then
    echo "  Python: pyproject.toml present"
  else
    echo "  Python: requirements.txt / setup.py present"
  fi
  PY_FILES=()
  [ -f "$PROJECT_ROOT/pyproject.toml" ] && PY_FILES+=("$PROJECT_ROOT/pyproject.toml")
  [ -f "$PROJECT_ROOT/requirements.txt" ] && PY_FILES+=("$PROJECT_ROOT/requirements.txt")
  [ -f "$PROJECT_ROOT/setup.py" ] && PY_FILES+=("$PROJECT_ROOT/setup.py")
  if grep -qE 'fastapi|flask|django|starlette|sanic|tornado|aiohttp' "${PY_FILES[@]}" 2>/dev/null; then
    DOMAIN_HINTS+=("api-design")
  fi
  if grep -qE 'sqlalchemy|django|peewee|tortoise-orm|asyncpg|psycopg' "${PY_FILES[@]}" 2>/dev/null; then
    DOMAIN_HINTS+=("data-layer")
  fi
fi

# Multi-service / distributed
if [ -f "$PROJECT_ROOT/docker-compose.yml" ] || [ -f "$PROJECT_ROOT/docker-compose.yaml" ] || [ -d "$PROJECT_ROOT/k8s" ] || [ -d "$PROJECT_ROOT/kubernetes" ] || [ -d "$PROJECT_ROOT/charts" ]; then
  SIGNALS_FOUND=1
  echo "  multi-service: docker-compose / k8s / charts detected"
  DOMAIN_HINTS+=("distributed-systems")
fi

if [ "$SIGNALS_FOUND" -eq 0 ]; then
  echo "  (no recognized manifest — language/framework not auto-detected)"
fi

# --- 5. Mental model suggestions (deduplicated) ---
if [ "${#DOMAIN_HINTS[@]}" -gt 0 ]; then
  UNIQUE_HINTS=$(printf '%s\n' "${DOMAIN_HINTS[@]}" | sort -u)
  echo ""
  echo "Suggested mental models (read on demand if relevant to the current decision):"
  while IFS= read -r h; do
    MM_FILE="$HOME/.bocek/mental-models/$h.md"
    if [ -f "$MM_FILE" ]; then
      echo "  ~/.bocek/mental-models/$h.md"
    fi
  done <<< "$UNIQUE_HINTS"
else
  echo ""
  echo "Mental models: no auto-match. Browse ~/.bocek/mental-models/ if a domain applies."
fi

# --- 5b. Idiom suggestions (ecosystem quality bars — read on activation, not on demand) ---
if [ "${#IDIOM_HINTS[@]}" -gt 0 ]; then
  UNIQUE_IDIOMS=$(printf '%s\n' "${IDIOM_HINTS[@]}" | sort -u)
  echo ""
  echo "Suggested idioms (read on activation — these encode the production-grade default for this stack):"
  while IFS= read -r i; do
    IDIOM_FILE="$HOME/.bocek/idioms/$i.md"
    if [ -f "$IDIOM_FILE" ]; then
      echo "  ~/.bocek/idioms/$i.md"
    fi
  done <<< "$UNIQUE_IDIOMS"
fi

# --- 6. Mode-specific eager references ---
echo ""
echo "Eager references for ${MODE} (read these now, before responding):"
case "$MODE" in
  design)
    echo "  ~/.bocek/references/shared/vault-format.md"
    echo "  ~/.bocek/references/shared/calibration.md"
    ;;
  research)
    echo "  ~/.bocek/references/research/research-format.md"
    echo "  ~/.bocek/references/shared/calibration.md"
    ;;
  implementation)
    echo "  ~/.bocek/references/shared/session-continuity.md"
    echo "  ~/.bocek/references/implementation/contract-following.md"
    ;;
  debugging)
    echo "  ~/.bocek/references/shared/session-continuity.md"
    echo "  ~/.bocek/references/debugging/trace-protocol.md"
    ;;
  refactoring)
    echo "  ~/.bocek/references/shared/session-continuity.md"
    echo "  ~/.bocek/references/refactoring/behavior-mapping.md"
    ;;
  review)
    echo "  ~/.bocek/references/shared/vault-format.md"
    echo "  ~/.bocek/references/shared/calibration.md"
    echo "  ~/.bocek/references/review/vault-compliance.md"
    ;;
  idle)
    ;;
esac

# CONTEXT.md is eager-read for every primitive activation per [[context-md-as-vocabulary]]
if [ -f "$VAULT_DIR/CONTEXT.md" ] && [ "$MODE" != "idle" ]; then
  echo "  $VAULT_DIR/CONTEXT.md  (project-domain vocabulary — read on every primitive activation)"
fi

# --- 6b. Project state classification (greenfield / brownfield-with-vault / brownfield-no-vault) ---
# Code count: source files in common locations, excluding vendored/build/dot dirs
CODE_COUNT=$(find "$PROJECT_ROOT" \
  \( -path "*/node_modules" -o -path "*/vendor" -o -path "*/dist" -o -path "*/build" -o -path "*/.next" -o -path "*/.git" -o -path "*/target" -o -path "*/.bocek" -o -path "*/__pycache__" -o -path "*/.venv" -o -path "*/venv" \) -prune \
  -o -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.go" -o -name "*.py" -o -name "*.rs" -o -name "*.java" -o -name "*.rb" -o -name "*.php" -o -name "*.swift" -o -name "*.kt" -o -name "*.cs" \) -print 2>/dev/null \
  | wc -l | tr -d ' ')

echo ""
if [ "$ENTRY_COUNT" -gt 0 ]; then
  PROJECT_STATE="brownfield-with-vault"
  echo "Project state: brownfield-with-vault (existing code + $ENTRY_COUNT vault entries)"
elif [ "$CODE_COUNT" -ge 10 ]; then
  PROJECT_STATE="brownfield-no-vault"
  echo "Project state: brownfield-no-vault ($CODE_COUNT source files, 0 vault entries)"
  echo "  ⚠ Read ~/.bocek/references/shared/onboarding.md before first action."
  echo "    Two paths: forward-vault only, or reverse archaeology. Human picks."
else
  PROJECT_STATE="greenfield"
  echo "Project state: greenfield ($CODE_COUNT source files, 0 vault entries)"
  echo "  First decision is *project shape*. Run \`bocek bootstrap\` for an interactive interview,"
  echo "  or read ~/.bocek/references/shared/onboarding.md for the question set."
fi

echo ""
echo "=== Mode set: ${MODE}. Enforcement hook is active. ==="
