#!/usr/bin/env bash
# Install Agent Skills from this repo into one or more agent skill directories.
#
# Defaults: symlink every skill in ./skills/ into ~/.claude/skills/
# (which Claude Code reads, and Cursor 2.4+ also reads natively).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$REPO_DIR/skills"

# Defaults.
TARGETS=()
SKILL_FILTER=""
EXPLICIT_TARGET=""
COPY_MODE=0
UNINSTALL=0
DRY_RUN=0

# Known per-agent install dirs. Edit to add more.
DIR_CLAUDE="$HOME/.claude/skills"
DIR_CURSOR="$HOME/.cursor/skills"
DIR_CODEX="$HOME/.codex/skills"
DIR_GEMINI="$HOME/.gemini/skills"

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Targets (default: --claude):
  --claude              Install to ~/.claude/skills/ (also covers Cursor 2.4+)
  --cursor              Install to ~/.cursor/skills/
  --codex               Install to ~/.codex/skills/
  --gemini              Install to ~/.gemini/skills/
  --all                 Install to all known agent dirs above
  --target <dir>        Install to an explicit directory (overrides --claude/etc.)

Selection:
  --skill <name>        Install only the named skill (default: all skills in ./skills/)

Mode:
  --copy                Copy files instead of symlinking
  --uninstall           Remove symlinks/copies from selected target(s) for selected skill(s)
  --dry-run             Print what would happen, don't change the filesystem

  -h, --help            Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --claude) TARGETS+=("$DIR_CLAUDE"); shift ;;
    --cursor) TARGETS+=("$DIR_CURSOR"); shift ;;
    --codex) TARGETS+=("$DIR_CODEX"); shift ;;
    --gemini) TARGETS+=("$DIR_GEMINI"); shift ;;
    --all) TARGETS+=("$DIR_CLAUDE" "$DIR_CURSOR" "$DIR_CODEX" "$DIR_GEMINI"); shift ;;
    --target) EXPLICIT_TARGET="$2"; shift 2 ;;
    --skill) SKILL_FILTER="$2"; shift 2 ;;
    --copy) COPY_MODE=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -n "$EXPLICIT_TARGET" ]]; then
  TARGETS=("$EXPLICIT_TARGET")
fi

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  TARGETS=("$DIR_CLAUDE")
fi

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "No skills directory at $SKILLS_DIR" >&2
  exit 1
fi

# Build skill list.
SKILLS=()
if [[ -n "$SKILL_FILTER" ]]; then
  if [[ -d "$SKILLS_DIR/$SKILL_FILTER" ]]; then
    SKILLS+=("$SKILL_FILTER")
  else
    echo "Skill not found: $SKILL_FILTER" >&2
    exit 1
  fi
else
  for d in "$SKILLS_DIR"/*/; do
    [[ -d "$d" ]] || continue
    SKILLS+=("$(basename "$d")")
  done
fi

if [[ ${#SKILLS[@]} -eq 0 ]]; then
  echo "No skills to install." >&2
  exit 1
fi

run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY-RUN: $*"
  else
    "$@"
  fi
}

for target in "${TARGETS[@]}"; do
  # Expand ~ if present.
  target="${target/#\~/$HOME}"

  if [[ $UNINSTALL -eq 1 ]]; then
    for skill in "${SKILLS[@]}"; do
      dest="$target/$skill"
      if [[ -L "$dest" || -d "$dest" ]]; then
        run rm -rf "$dest"
        echo "Removed $dest"
      fi
    done
    continue
  fi

  run mkdir -p "$target"

  for skill in "${SKILLS[@]}"; do
    src="$SKILLS_DIR/$skill"
    dest="$target/$skill"

    if [[ -e "$dest" || -L "$dest" ]]; then
      # If it's already a symlink to the same place, skip.
      if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
        echo "Up to date: $dest"
        continue
      fi
      echo "Replacing existing: $dest"
      run rm -rf "$dest"
    fi

    if [[ $COPY_MODE -eq 1 ]]; then
      run cp -R "$src" "$dest"
      echo "Copied $skill -> $dest"
    else
      run ln -s "$src" "$dest"
      echo "Linked $skill -> $dest"
    fi
  done
done

echo
echo "Done. Restart your agent if it caches the skills directory at startup."
