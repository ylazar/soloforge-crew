# Agent Guards — Threat Model

The `agent-guards.sh` script intercepts a small number of common commands an
agent might use to read secrets from the shell environment. It replaces them
with friendly refusals that surface the request to the human user.

This document records what this defends against and — more importantly —
what it does *not* defend against, so neither the operator nor the
implementer mistakes a soft guard for a hard control.

## Threat model

**Goal**: reduce the probability that an agent prints a secret value into its
own context window — where it would be cached, possibly logged, possibly
copied into a follow-up prompt to a different model, and possibly stored on
a third-party server.

**Adversary**: a benign-but-overeager agent. The threat is *the agent's
helpfulness*, not malice. An agent told "look up my API key" will, by
default, do exactly that. The guard reframes the request: "you don't have
direct access; ask the user."

**Out of scope**: a malicious agent, a compromised MCP server, or an
attacker who has already gained shell access. None of those are stopped by
this layer.

## What is defended

| Vector | Mechanism |
|---|---|
| `env` printing all values | Function shadow returns names only |
| `printenv $SECRET` for well-known names | Function shadow returns refusal |
| `cat .env`, `cat *credentials*`, `cat *.pem` | Function shadow returns refusal |
| `gh auth token` (full-scope OAuth bearer) | Function shadow returns refusal |

## What is NOT defended

| Bypass | Why guards don't catch it |
|---|---|
| `command env` | `command` explicitly bypasses functions; the guard is by design overridable |
| `/usr/bin/env` (absolute path) | Functions are looked up only for unqualified names |
| `bash -c 'env'` | New shell doesn't load `.zshenv` (or loads it without `$CLAUDECODE` set in some cases) |
| `cat /proc/$$/environ \| tr '\0' '\n'` | `cat` shadow only checks for `.env`-style filenames |
| `awk 'BEGIN{for(v in ENVIRON) print v"="ENVIRON[v]}'` | Awk reads ENVIRON directly; no shell function intercept |
| `python3 -c 'import os; print(os.environ)'` | Python's `os.environ` is a syscall; no shell layer |
| `node -e 'console.log(process.env)'` | Same — language runtime reads via syscall |
| Reading `~/.aws/credentials` directly (not via cat) | Read tool would bypass the cat function entirely |

## Real defense remains

These are the controls that actually matter. The guard is supplementary.

1. **`.env` outside the repo, in `.gitignore`** — keep secrets off disk inside
   working trees that agents traverse.
2. **Fine-grained PATs over OAuth tokens** — limit blast radius of any token
   the agent can reach. Per CISO rule, the GitHub MCP should use a read-only
   fine-grained PAT, not the full-scope `gh` OAuth token.
3. **Secret manager + short-lived tokens** — rotate frequently; expired
   tokens limit damage when leaked.
4. **MCP server hygiene** — review `.claude/`, `mcp.json`, `~/.claude.json`
   diffs from any inbound source (git pull, branch checkout, cloned repo)
   before opening Claude Code on the working tree. Per CISO rule on the MCP
   STDIO architectural RCE.
5. **Minimize plaintext secrets under HOME** — anything in HOME is reachable
   by any agent process. Migrate to a secret manager when possible.

## When the guard fires unexpectedly

If a real workflow needs to read a guarded value:

1. The agent should explain *why* it needs the value.
2. The user provides it directly (paste, file path, or temporary env var
   that the user sets and unsets manually).
3. Never instruct the agent to bypass the guard via `command`, absolute
   paths, or alternative tools — if the guard is wrong, the right fix is to
   refine the guard list, not to teach the agent to evade it.

## Telemetry

The guard does not log invocations. If you want a record of when secrets
were *attempted*, add a logging line to the relevant function:

```bash
echo "$(date -u +%FT%TZ) agent-guards refused: env" >> ~/.agent_guards.log
```

Off by default — logs in HOME are themselves sensitive.
