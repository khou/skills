#!/usr/bin/env bash
# Install Agent Skills and slash commands from this repo into your agent's
# config directories.
#
# Defaults: symlink everything in ./skills/ and ./commands/ into the
# Claude Code dirs (~/.claude/skills/ and ~/.claude/commands/).
# Cursor 2.4+ also reads ~/.claude/skills/ natively.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$REPO_DIR/skills"
COMMANDS_SRC="$REPO_DIR/commands"

# Defaults.
TARGETS=()  # "<agent>:<skill-dir>:<commands-dir>"; commands-dir empty if N/A.
SKILL_FILTER=""
COMMAND_FILTER=""
EXPLICIT_TARGET_SKILLS=""
EXPLICIT_TARGET_COMMANDS=""
COPY_MODE=0
UNINSTALL=0
DRY_RUN=0
WHAT="both"  # both | skills | commands

# Known per-agent install dirs.
T_CLAUDE="claude:$HOME/.claude/skills:$HOME/.claude/commands"
T_CURSOR="cursor:$HOME/.cursor/skills:"
T_CODEX="codex:$HOME/.codex/skills:"
T_GEMINI="gemini:$HOME/.gemini/skills:"

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Targets (default: --claude):
  --claude                Install to ~/.claude/{skills,commands}/
                          (Cursor 2.4+ also reads ~/.claude/skills/)
  --cursor                Install skills to ~/.cursor/skills/ (no commands path)
  --codex                 Install skills to ~/.codex/skills/ (no commands path)
  --gemini                Install skills to ~/.gemini/skills/ (no commands path)
  --all                   Install to all known agents above
  --target-skills <dir>   Override skills install dir (one path)
  --target-commands <dir> Override commands install dir (one path)

What:
  --skills-only           Install only skills (./skills/*)
  --commands-only         Install only commands (./commands/*)
  --skill <name>          Install only the named skill
  --command <name>        Install only the named command (with or without .md)

Mode:
  --copy                  Copy instead of symlinking
  --uninstall             Remove links/copies for selected items from selected target(s)
  --dry-run               Print what would happen
  -h, --help              Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --claude) TARGETS+=("$T_CLAUDE"); shift ;;
    --cursor) TARGETS+=("$T_CURSOR"); shift ;;
    --codex) TARGETS+=("$T_CODEX"); shift ;;
    --gemini) TARGETS+=("$T_GEMINI"); shift ;;
    --all) TARGETS+=("$T_CLAUDE" "$T_CURSOR" "$T_CODEX" "$T_GEMINI"); shift ;;
    --target-skills) EXPLICIT_TARGET_SKILLS="$2"; shift 2 ;;
    --target-commands) EXPLICIT_TARGET_COMMANDS="$2"; shift 2 ;;
    --skills-only) WHAT="skills"; shift ;;
    --commands-only) WHAT="commands"; shift ;;
    --skill) SKILL_FILTER="$2"; shift 2 ;;
    --command) COMMAND_FILTER="${2%.md}"; shift 2 ;;
    --copy) COPY_MODE=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -n "$EXPLICIT_TARGET_SKILLS$EXPLICIT_TARGET_COMMANDS" ]]; then
  TARGETS=("explicit:${EXPLICIT_TARGET_SKILLS}:${EXPLICIT_TARGET_COMMANDS}")
fi

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  TARGETS=("$T_CLAUDE")
fi

run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY-RUN: $*"
  else
    "$@"
  fi
}

# Build skill list.
SKILLS=()
if [[ "$WHAT" != "commands" && -d "$SKILLS_SRC" ]]; then
  if [[ -n "$SKILL_FILTER" ]]; then
    if [[ -d "$SKILLS_SRC/$SKILL_FILTER" ]]; then
      SKILLS+=("$SKILL_FILTER")
    else
      echo "Skill not found: $SKILL_FILTER" >&2; exit 1
    fi
  else
    for d in "$SKILLS_SRC"/*/; do
      [[ -d "$d" ]] || continue
      SKILLS+=("$(basename "$d")")
    done
  fi
fi

# Build command list.
COMMANDS=()
if [[ "$WHAT" != "skills" && -d "$COMMANDS_SRC" ]]; then
  if [[ -n "$COMMAND_FILTER" ]]; then
    if [[ -f "$COMMANDS_SRC/$COMMAND_FILTER.md" ]]; then
      COMMANDS+=("$COMMAND_FILTER")
    else
      echo "Command not found: $COMMAND_FILTER" >&2; exit 1
    fi
  else
    for f in "$COMMANDS_SRC"/*.md; do
      [[ -f "$f" ]] || continue
      COMMANDS+=("$(basename "$f" .md)")
    done
  fi
fi

if [[ ${#SKILLS[@]} -eq 0 && ${#COMMANDS[@]} -eq 0 ]]; then
  echo "Nothing to install." >&2; exit 1
fi

install_one() {
  local kind="$1"  # skill | command
  local name="$2"
  local target_dir="$3"
  local src dest

  target_dir="${target_dir/#\~/$HOME}"

  if [[ "$kind" == "skill" ]]; then
    src="$SKILLS_SRC/$name"
    dest="$target_dir/$name"
  else
    src="$COMMANDS_SRC/$name.md"
    dest="$target_dir/$name.md"
  fi

  if [[ $UNINSTALL -eq 1 ]]; then
    if [[ -L "$dest" || -e "$dest" ]]; then
      run rm -rf "$dest"
      echo "Removed $dest"
    fi
    return
  fi

  run mkdir -p "$target_dir"

  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
      echo "Up to date: $dest"
      return
    fi
    echo "Replacing existing: $dest"
    run rm -rf "$dest"
  fi

  if [[ $COPY_MODE -eq 1 ]]; then
    run cp -R "$src" "$dest"
    echo "Copied $kind $name -> $dest"
  else
    run ln -s "$src" "$dest"
    echo "Linked $kind $name -> $dest"
  fi
}

for entry in "${TARGETS[@]}"; do
  IFS=':' read -r agent skill_dir command_dir <<< "$entry"

  # Skills go to every target that defines a skill_dir.
  if [[ -n "$skill_dir" && ${#SKILLS[@]} -gt 0 ]]; then
    for skill in "${SKILLS[@]}"; do
      install_one skill "$skill" "$skill_dir"
    done
  fi

  # Commands only go to targets that define a command_dir.
  if [[ -n "$command_dir" && ${#COMMANDS[@]} -gt 0 ]]; then
    for cmd in "${COMMANDS[@]}"; do
      install_one command "$cmd" "$command_dir"
    done
  elif [[ -z "$command_dir" && ${#COMMANDS[@]} -gt 0 && "$agent" != "claude" ]]; then
    if [[ "$WHAT" == "commands" ]]; then
      echo "Note: $agent has no native slash-commands path; skipping commands."
    fi
  fi
done

echo
echo "Done. Restart your agent if it caches its config at startup."
