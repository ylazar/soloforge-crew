---
name: install-agent-guards
description: Installs soft shell-level guardrails (gated on $CLAUDECODE) that override env, printenv, cat on .env, and gh auth token to require explicit human approval rather than printing secrets to agent context. Source-of-truth lives in this skill's sibling scripts/ directory; instance is copied to $HOME/.agent_guards.sh and sourced from ~/.zshenv. Run when the user asks to install agent guards, harden agent shell, or reduce accidental secret exposure.
---

# Install Agent Guards

Installs `~/.agent_guards.sh` (a soft shell-level guard against accidental secret exposure) and ensures `~/.zshenv` sources it. The script is gated on `$CLAUDECODE` so non-Claude shells are unaffected.

## What this defends against

Casual exfiltration of secrets via:
- `env` printing all values
- `printenv ANTHROPIC_API_KEY` (and similar known-sensitive names)
- `cat .env`, `cat ~/.aws/credentials`, etc.
- `gh auth token` (returns the OAuth bearer)

## What it does NOT defend against

See `reference/threat-model.md`. Briefly:
- Direct invocation: `/usr/bin/env`, `command env`, `bash -c env`
- `/proc/<pid>/environ` reads
- Python/Node REPLs reading `os.environ` / `process.env`
- Determined exfiltration via base64 or other encoding

This is a *floor*, not a ceiling. Real defense remains: `.env` outside git, fine-grained PATs over OAuth tokens, secrets in a manager, regular rotation.

## Workflow

1. Read `./agent-guards.sh` (the source-of-truth, alongside this SKILL.md).
2. If `~/.agent_guards.sh` already exists, diff it against the source and show the diff.
3. Ask the user to approve the install (or update).
4. On approval:
   - Copy `./agent-guards.sh` to `~/.agent_guards.sh`
   - Ensure `~/.zshenv` contains: `[[ -f "$HOME/.agent_guards.sh" ]] && source "$HOME/.agent_guards.sh"`
   - Idempotent: grep for the source line first; only append if missing.
5. Print verification instructions:
   - "Open a new shell and run `env | head -3` — should be variable names only."
   - "Run `printenv ANTHROPIC_API_KEY` — should be refused."
   - "Run `cat /path/to/.env` — should be refused."

## What is NOT done by this skill

- Does not modify the source-of-truth `./agent-guards.sh`. To change behavior, edit the script in soloforge-crew (or your installed copy), then re-run this skill to refresh `~/.agent_guards.sh`.
- Does not commit anything to repos.
- Does not export, set, or read secret values.

## Updating

When the script in soloforge-crew is updated:

1. Re-run this skill.
2. The diff phase will show changes.
3. Approve to refresh `~/.agent_guards.sh`.
4. Open a new shell to pick up the changes (existing shells keep the old definitions).

## Related

- CISO rule: `MCP STDIO transport — architectural RCE` — explains why minimizing plaintext secrets under HOME matters.
- CISO rule: `GitHub MCP / gh OAuth full-write scope` — explains the gh auth token block.
