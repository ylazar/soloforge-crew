---
name: threat-intel
description: >
  Daily security brief. Scans threat feeds, scores relevance against the
  repo's tech stack, writes a structured report, and proposes agentic
  remediation actions. Run once per day, ideally before roadmap work.
argument-hint: "<no-argument>"
---

# Threat Intel — Daily Security Brief

Produce a daily CISO brief: scan the threat landscape, score relevance to
this repo, write a structured report, and propose concrete actions.

## When to use

- Start of the work day, before `/proceed` or other roadmap work
- After hearing about a new vulnerability or supply chain attack
- The `/proceed` skill nudges you to run this if no brief exists for today

## When NOT to use

- A brief for today already exists (`knowledge/roles/ciso/articles/generated/daily-YYYY-MM-DD.md`)
- You need a deep-dive on a specific CVE — use `/research` scoped to ciso instead
- You want to review code for security issues — spawn the CISO agent directly

---

## Phase 1: Profile the Repo

Build a compact security profile of this project. Read (do not modify):

1. `CLAUDE.md` — tech stack, languages, deployment targets
2. `.claude/agents/` — list agent files to understand agentic capabilities
   (which tools are available? Bash? Write? Edit?)
3. Dependency manifests — scan for `package.json`, `pyproject.toml`,
   `requirements.txt`, `Cargo.toml`, `go.mod`, `Gemfile`, or equivalent.
   Read the first one found to identify external dependencies.
4. `.claude/settings.local.json` or `.claude/settings.json` — check for
   MCP servers configured (these are part of the attack surface)
5. `knowledge/roles/ciso/` — read any existing notes or articles to
   understand prior security context

Summarize into a "Repo Security Profile" (keep in working memory, do not
write to a file):
- **Languages & frameworks** in use
- **Key dependencies** (top 10-15 by importance)
- **MCP servers** configured
- **Agent tool surface** (can agents run Bash? Write files?)
- **Data stores** (DB, file-based, cloud services)
- **Prior security context** from CISO knowledge base

**Gate:** NONE

---

## Phase 2: Scan Threat Landscape

Search for recent security threats relevant to this repo's profile.

1. Read `knowledge/docs/priority-sources.md` for any security-specific
   trusted sources
2. Read filenames in `knowledge/roles/ciso/articles/external/` to avoid
   re-covering threats already ingested
3. Run `date -u '+%Y-%m-%d'` to get today's date for the report filename
4. WebSearch with 3-4 queries, substituting `<lang>` and `<framework>`
   from the repo profile:

   - `"supply chain attack" OR "dependency hijack" <lang> site:github.com/advisories OR site:socket.dev` (recent)
   - `"MCP server" OR "claude code" OR "AI coding agent" vulnerability OR exploit` (recent)
   - `"prompt injection" OR "tool use" security <framework>` (recent)
   - `<lang> CVE 2026` OR `<framework> security advisory` (recent)

   Adjust queries based on what the repo actually uses — skip irrelevant
   technology terms. Prefer recent results (last 7 days).

5. For each promising result (up to 8), use WebFetch to retrieve details.
   Stop fetching if a result is paywalled, irrelevant, or a duplicate of
   something already in the knowledge base.

**Gate:** NONE

---

## Phase 3: Score Relevance

For each threat identified, score on three axes (1-5):

| Axis | 1 | 3 | 5 |
|------|---|---|---|
| **Applicability** | Unrelated technology | Same language/ecosystem | Exact dependency or tool match |
| **Severity** | Informational | Moderate impact, requires specific conditions | Critical, remote code execution or data exfiltration |
| **Proximity** | Theoretical, no known exploit | PoC exists, limited exploitation | Actively exploited in the wild |

Compute composite relevance:
```
relevance = (applicability * 2 + severity + proximity) / 4
```

**Filter:** Only include threats with relevance >= 2.5 in the brief.
Discard the rest (mention count discarded in the executive summary).

**Gate:** NONE

---

## Phase 4: Write the Daily Brief

Run `date -u '+%Y-%m-%d %H:%M UTC'` to get the timestamp.

Save to `knowledge/roles/ciso/articles/generated/daily-YYYY-MM-DD.md`:

```markdown
# CISO Daily Brief — YYYY-MM-DD
_Created: YYYY-MM-DD HH:MM UTC_
_Type: LLM-generated synthesis_
_Repo: <project name from CLAUDE.md>_

## Executive Summary
<2-3 sentences: top threats today, overall risk posture, N threats scanned,
N included after relevance filtering>

## Threat Analysis

### 1. <Threat title> — Relevance: X.X/5
- **What:** <1-2 sentences>
- **Applicability:** X/5 — <why this repo is/isn't affected>
- **Severity:** X/5 — <impact if exploited>
- **Proximity:** X/5 — <actively exploited? PoC available?>
- **Source:** <URL>
- **Recommended action:** <specific to this repo>

### 2. ...
(repeat for each threat with relevance >= 2.5, ordered by relevance descending)

## Sources Consulted
<List of all URLs fetched during Phase 2, with one-line descriptions>
```

If no threats meet the relevance threshold, write a brief with:
```markdown
## Executive Summary
No threats with relevance >= 2.5 found today. N threats scanned across
<search domains>. Repo security posture unchanged from previous brief.
```

**Gate:** SOFT — present the brief to the user before proceeding to ingestion
and actions. The user may want to adjust scores or add context.

---

## Phase 5: Ingest High-Relevance Sources

For threats with relevance >= 4.0:

1. Save the source article to `knowledge/roles/ciso/articles/external/<descriptive-slug>.md`
   as a faithful markdown conversion (per article provenance rules — no summarization)
2. Add metadata header:
   ```
   # <Article Title>
   _Created: YYYY-MM-DD HH:MM UTC_
   _Source: <URL>_
   _Fetched: YYYY-MM-DD HH:MM UTC_
   _Role: ciso_
   ```

For all threats included in the brief:
3. Update `knowledge/roles/ciso/INDEX.md` — add entries for newly ingested
   articles and the daily brief itself

Present a summary to the user:
- Number of threats analyzed
- Number included in brief (relevance >= 2.5)
- Number of sources ingested (relevance >= 4.0)
- Top threat (highest relevance score)

**Gate:** NONE

---

## Phase 6: Propose Actions

This is the agentic core. For each recommended action from the brief,
classify it by whether the agent can execute it autonomously:

**AUTO actions (agent can execute with user approval):**
- Dependency updates (edit manifest, run package manager)
- Codebase audits (Grep for vulnerable patterns, report findings)
- Config hardening (edit config files, add security headers)
- Rule/guardrail updates (edit `.claude/rules/ciso/security-guardrails.md`)
- Knowledge base updates (save new security notes or patterns)

**MANUAL actions (require human action):**
- Secret rotation (API keys, tokens, passwords)
- Service configuration (enable 2FA, change permissions)
- External service actions (update DNS, configure WAF)
- Anything requiring credentials the agent doesn't have

Present to the user:
```
## Recommended Actions

1. [AUTO] <description> — <reason/CVE>
2. [AUTO] <description> — <reason/CVE>
3. [MANUAL] <description> — <reason/CVE>

Which actions should I execute? (all / 1,2 / none / defer)
```

**Response handling:**
- **`all`**: Execute all AUTO actions sequentially, documenting each change.
  For MANUAL actions, check `MANUAL_SETUP.md` — if the step isn't documented
  there, add it before asking the user to act.
- **`1,2,...`**: Execute only the selected AUTO actions.
- **`none`**: Brief is informational only. No changes made.
- **`defer`**: Append all action items to
  `knowledge/roles/ciso/notes/action-backlog.md` with today's date,
  for execution in a future session.

**Gate:** HARD — never execute actions without explicit user approval.
The brief is the report; this phase is the response.

---

## Rules

- **One brief per day** — if `daily-YYYY-MM-DD.md` already exists for today,
  tell the user and stop (unless they explicitly ask to regenerate)
- **No false urgency** — if nothing relevant is found, say so clearly.
  An empty brief is better than inflated threats.
- **Cite sources** — every threat must link to its source URL
- **Repo-specific, not generic** — recommendations must reference actual
  files, dependencies, or configurations in this project
- **Faithful ingestion** — source articles saved to `external/` are faithful
  markdown conversions, never summarized
- **Timestamps** — always run `date -u` for real timestamps, never guess
