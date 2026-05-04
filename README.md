# Coding agent skills

Cross-agent coding skills and slash commands. Drop them into Claude Code, Cursor, Codex CLI, Gemini CLI, GitHub Copilot, and any other tool that speaks the [Agent Skills](https://agentskills.io/) spec.

## What's a skill? What's a command?

- **Agent Skill**: a folder with a `SKILL.md` file (YAML frontmatter `name` + `description`, then markdown body). Portable: the same folder works in every tool that adopted the [Agent Skills spec](https://github.com/anthropics/skills/blob/main/spec/agent-skills-spec.md).
- **Slash command**: a single markdown file with a one-line `description` frontmatter. Claude Code's `~/.claude/commands/<name>.md` convention. Other agents have their own command systems; you can paste the body in as a custom command or rule.

This repo contains both.

## What's in here

| Skill | What it does |
| --- | --- |
| [`local-review`](skills/local-review/SKILL.md) | Multi-agent local code review. Spawns six parallel subagents (security, bugs/correctness, code quality, consistency, docs, customer-facing doc clarity) and aggregates findings with a `ship` / `fix-blockers` / `needs-rework` recommendation. |

| Command | What it does |
| --- | --- |
| [`/check-consistency`](commands/check-consistency.md) | Iteratively hunts for inconsistencies across the entire codebase (naming drift, signature drift, doc drift, partial migrations) and fixes them. Loops until a clean pass. |
| [`/check-pr-description`](commands/check-pr-description.md) | Audits a PR description against the actual diff and tightens it. Cuts iteration narration, stale claims, padding, speculative content. |

## Install

The fastest path:

```bash
git clone https://github.com/khou/skills.git ~/code/khou-skills
cd ~/code/khou-skills
./install.sh
```

By default `install.sh` symlinks every skill in `skills/` into `~/.claude/skills/` **and** every command in `commands/` into `~/.claude/commands/`. The skills location works for **both Claude Code and Cursor** (Cursor 2.4+ reads `~/.claude/skills/` natively).

### Per-agent options

```bash
./install.sh                       # Claude Code (skills + commands; covers Cursor for skills)
./install.sh --cursor              # Cursor (~/.cursor/skills/, skills only)
./install.sh --codex               # Codex CLI (~/.codex/skills/, skills only)
./install.sh --gemini              # Gemini CLI (~/.gemini/skills/, skills only)
./install.sh --all                 # all of the above

./install.sh --skills-only         # skip slash commands
./install.sh --commands-only       # skip skills (Claude Code only by default)

./install.sh --skill local-review        # one specific skill
./install.sh --command check-consistency # one specific command

./install.sh --copy                # copy instead of symlink (no auto-update on git pull)
./install.sh --uninstall           # remove links/copies created by this script
./install.sh --target-skills <dir> # explicit skills target dir
./install.sh --target-commands <dir> # explicit commands target dir
./install.sh --dry-run             # print what would happen, change nothing
```

Symlinks are the default so `git pull` auto-updates the installed skills and commands. Use `--copy` if your tool doesn't follow symlinks.

### Per-agent compatibility

| Agent | Skills | Slash commands | Source |
| --- | --- | --- | --- |
| Claude Code | Native, `~/.claude/skills/` | Native, `~/.claude/commands/` | [docs](https://code.claude.com/docs/en/skills) |
| Cursor | Native (2.4+), `~/.cursor/skills/` (also reads `~/.claude/skills/`) | Custom commands UI | [docs](https://cursor.com/docs/skills) |
| OpenAI Codex CLI | Native, `~/.codex/skills/` | per agent config | [docs](https://developers.openai.com/codex/skills/) |
| Gemini CLI | Native, `~/.gemini/skills/` | per agent config | [docs](https://geminicli.com/docs/cli/skills/) |
| GitHub Copilot / VS Code | Native | per agent config | [docs](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills) |
| OpenCode, Roo Code, Goose, Amp, Junie, Kiro, Factory | Native | varies | [agentskills.io](https://agentskills.io/) |
| Cline | Manual: paste body into `.clinerules/` | Manual | manual |
| Windsurf | Manual: paste body into `.windsurf/rules/` | Manual | manual |
| Aider | Manual: cat into `CONVENTIONS.md` | Manual | manual |
| Continue.dev | Manual: paste into `.continue/` rules | Manual | manual |

For tools without native Agent Skills support, copy the body of `SKILL.md` (skip the YAML frontmatter) into the tool's rules/conventions file. Same for slash command bodies.

### Project-scoped install

Run the installer from a project root with explicit targets to install repo-locally:

```bash
cd ~/your-project
~/code/khou-skills/install.sh \
  --target-skills .claude/skills \
  --target-commands .claude/commands
```

Check the directory into git so collaborators get the skills automatically.

## Manual install (no script)

```bash
# Claude Code (skills location also works for Cursor 2.4+)
ln -s "$PWD/skills/local-review" ~/.claude/skills/local-review
ln -s "$PWD/commands/check-consistency.md" ~/.claude/commands/check-consistency.md
ln -s "$PWD/commands/check-pr-description.md" ~/.claude/commands/check-pr-description.md

# Cursor (project-scoped, skills only)
ln -s "$PWD/skills/local-review" ~/your-project/.cursor/skills/local-review

# Codex CLI
ln -s "$PWD/skills/local-review" ~/.codex/skills/local-review
```

## Using a skill or command

Once installed:
- Skills are discovered automatically based on the `description` field; agents route to them when a task matches.
- Slash commands run on demand: `/check-consistency`, `/check-pr-description`, `/local-review`.

## Contributing

Pull requests welcome. New skills follow the spec at [agentskills.io](https://agentskills.io/) and live under `skills/<name>/SKILL.md`. New slash commands live at `commands/<name>.md` with a `description` frontmatter line.

## License

MIT. See [LICENSE](LICENSE).
