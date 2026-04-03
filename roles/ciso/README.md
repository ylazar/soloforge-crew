# CISO Role

Security reviewer and daily threat intelligence for Claude Code projects.

## What you get

- **Agent** (`ciso.md`) — a read-only security reviewer that checks code for
  secrets, injection vulnerabilities, auth gaps, and dependency risks
- **Always-on rules** (`security-guardrails.md`) — loaded every session,
  enforcing secrets hygiene, input validation, and safe error handling
- **Daily brief skill** (`/threat-intel`) — scans threat feeds, scores
  relevance to your repo, writes a structured report, and proposes actions

## Daily workflow

1. Run `/threat-intel` at the start of your day
2. Review the brief in `knowledge/roles/ciso/articles/generated/` (incremental or broad)
3. Approve or defer the recommended actions
4. The CISO agent references recent briefs when reviewing code changes

## Customization

- **Priority sources**: Edit `knowledge/priority-sources.md` to add your
  trusted security feeds (CVE databases, vendor blogs, threat intel services)
- **Agent focus**: Edit `.claude/agents/ciso.md` to add project-specific
  security concerns (compliance frameworks, specific attack vectors)
- **Guardrails**: Edit `.claude/rules/ciso/security-guardrails.md` to add
  project-specific security rules

## Install

```bash
~/soloforge-crew/install.sh ciso ~/my-project
```
