# Coding agent skills

Cross-agent coding skills you can drop into Claude Code, Cursor, Codex CLI, Gemini CLI, GitHub Copilot, and any other tool that supports the [Agent Skills](https://agentskills.io/) spec.

## What's a skill?

An "Agent Skill" is a folder with a `SKILL.md` file that contains YAML frontmatter (`name`, `description`) and a markdown body describing how the agent should behave. The format is portable — the same folder works in every tool that adopted the spec.

## Skills in this repo

| Skill | What it does |
| --- | --- |
| [`local-review`](skills/local-review/SKILL.md) | Multi-agent local code review. Spawns six parallel subagents (security, bugs/correctness, code quality, consistency, docs, customer-facing doc clarity) and aggregates findings with a `ship` / `fix-blockers` / `needs-rework` recommendation. |

More to come.

## Install

The fastest path: clone this repo and run the installer.

```bash
git clone https://github.com/khou/skills.git ~/code/khou-skills
cd ~/code/khou-skills
./install.sh
```

By default `install.sh` symlinks every skill in `skills/` into `~/.claude/skills/`. That single location works for **both Claude Code and Cursor** (Cursor reads `~/.claude/skills/` natively as of 2.4).

### Per-agent options

```bash
./install.sh                  # Claude Code + Cursor (~/.claude/skills/)
./install.sh --cursor         # ~/.cursor/skills/ (project-side: .cursor/skills/)
./install.sh --codex          # ~/.codex/skills/
./install.sh --gemini         # ~/.gemini/skills/
./install.sh --all            # all of the above
./install.sh --copy           # copy instead of symlink (no auto-update on git pull)
./install.sh --skill local-review   # install just one skill
./install.sh --target ~/some/dir    # explicit target dir
./install.sh --uninstall      # remove symlinks/copies created by this script
```

Symlinks are the default because `git pull` then auto-updates the installed skills. Use `--copy` if your tool doesn't follow symlinks.

### Per-agent compatibility

| Agent | Status | Default install dir | Source |
| --- | --- | --- | --- |
| Claude Code | Native | `~/.claude/skills/` | [docs](https://code.claude.com/docs/en/skills) |
| Cursor | Native (2.4+) | `~/.cursor/skills/` (also reads `~/.claude/skills/`) | [docs](https://cursor.com/docs/skills) |
| OpenAI Codex CLI | Native | `~/.codex/skills/` | [docs](https://developers.openai.com/codex/skills/) |
| Gemini CLI | Native | `~/.gemini/skills/` | [docs](https://geminicli.com/docs/cli/skills/) |
| GitHub Copilot / VS Code | Native | per agent config | [docs](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills) |
| OpenCode, Roo Code, Goose, Amp, Junie, Kiro, Factory | Native | per agent config | [agentskills.io](https://agentskills.io/) |
| Cline | Workaround | `.clinerules/` (paste skill body, no frontmatter) | manual |
| Windsurf | Workaround | `.windsurf/rules/` or `.windsurfrules` | manual |
| Aider | Workaround | `CONVENTIONS.md` (`--read CONVENTIONS.md`) | manual |
| Continue.dev | Workaround | `.continue/` rules | manual |

For tools without native Agent Skills support, copy the body of `SKILL.md` (skip the YAML frontmatter) into whatever rules/conventions file the tool uses.

### Project-scoped install

Skills can also be installed into a project instead of globally. Run the installer from the project root with `--target .claude/skills` (or `.cursor/skills`, etc.) and check the directory into git so collaborators get it for free.

```bash
cd ~/your-project
~/code/khou-skills/install.sh --target .claude/skills
```

## Manual install (no script)

If you'd rather not run the installer:

```bash
# Claude Code (also works for Cursor 2.4+)
ln -s "$PWD/skills/local-review" ~/.claude/skills/local-review

# Cursor (project-scoped)
ln -s "$PWD/skills/local-review" ~/your-project/.cursor/skills/local-review

# Codex CLI
ln -s "$PWD/skills/local-review" ~/.codex/skills/local-review
```

## Using a skill

Once installed, agents discover skills automatically based on the `description` field in `SKILL.md`. You can also invoke directly:

- Claude Code: `/local-review` (or just describe the task and the harness routes to the skill)
- Cursor: ask the agent to do a local code review
- Codex / Gemini / Copilot: same — describe the task

## Contributing

Pull requests welcome. New skills should follow the spec at [agentskills.io](https://agentskills.io/) and live under `skills/<name>/SKILL.md` with optional supporting files alongside.

## License

MIT. See [LICENSE](LICENSE).
