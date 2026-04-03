---
name: threat-intel
description: >
  Security brief. Scans threat feeds, scores relevance against the
  repo's tech stack, writes a structured report, and proposes agentic
  remediation actions. Supports two modes: incremental (since last scan)
  and broad (full posture review). First run auto-triggers broad.
argument-hint: "[broad]"
---

# Threat Intel — Security Brief

Produce a CISO brief: scan the threat landscape, score relevance to
this repo, write a structured report, and propose concrete actions.

## When to use

- Start of the work day, before `/proceed` or other roadmap work
- After hearing about a new vulnerability or supply chain attack
- The `/proceed` skill nudges you to run this if no brief exists for today
- First time in a repo, or after major dependency changes — use `broad` mode

## When NOT to use

- You need a deep-dive on a specific CVE — use `/research` scoped to ciso instead
- You want to review code for security issues — spawn the CISO agent directly

---

## Modes

| Mode | Trigger | Scope | Time window |
|------|---------|-------|-------------|
| **incremental** (default) | `/threat-intel` with no argument | Threats since the last scan | From last brief's date to now |
| **broad** | `/threat-intel broad`, explicit request, or **automatic on first run** | All known threats for the repo's stack | No time limit — historical CVEs, advisories, and current threats |

**Mode detection:**
1. If the argument is `broad`, `posture`, `full`, or the user's prompt
   mentions "posture review", "full scan", or "initial review"
   → use **broad** mode
2. If no previous brief exists in
   `knowledge/roles/ciso/articles/generated/` (no `incremental-*.md` or
   `broad-*.md` files) → use **broad** mode automatically and tell the
   user: "No previous scan found — running **broad** mode (full posture
   review)"
3. Otherwise → use **incremental** mode. Determine the time window by
   reading the `_Created:` timestamp from the most recent brief file
   (sort by filename date descending). Cap the window at 30 days — if
   the last scan is older than 30 days, use broad mode instead and note:
   "Last scan is over 30 days old — switching to **broad** mode"

Announce the selected mode at the start:
- "Running in **incremental** mode (since YYYY-MM-DD, N days)"
- "Running in **broad** mode (full posture review)"

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

## Phase 2: Load Resolved Threats

Before scanning for new threats, load the resolved threats log to avoid
resurfacing issues that have already been handled.

1. Read `knowledge/roles/ciso/notes/resolved-threats.md` (if it exists)
2. Build a list of resolved threat identifiers — each entry has a slug,
   CVE ID, or description that can be matched against new search results
3. These will be used in Phase 3 to filter out already-handled threats

If the file doesn't exist, proceed with an empty resolved list.

**Gate:** NONE

---

## Phase 3: Scan Threat Landscape

Search for security threats relevant to this repo's profile.

1. Read `knowledge/docs/priority-sources.md` for any security-specific
   trusted sources
2. Read filenames in `knowledge/roles/ciso/articles/external/` to avoid
   re-ingesting sources already in the knowledge base
3. Run `date -u '+%Y-%m-%d'` to get today's date for the report filename

### Constructing search queries

Substitute `<lang>` and `<framework>` from the repo profile into the
query templates below.

**Incremental mode — time-bounded queries (since last scan):**

Use the last scan date determined during mode detection. Compute the
number of days since that date. Add explicit date qualifiers to every
query to constrain results to that window. Strategies:

- Append the year and month (e.g., `"April 2026"` or `"2026-04"`)
- Use `after:YYYY-MM-DD` on search engines that support it
- Include "latest" or "new" as signal words

Query templates (3-4 queries):
```
"supply chain attack" OR "dependency hijack" <lang> <date-qualifier>
"MCP server" OR "claude code" OR "AI coding agent" vulnerability <date-qualifier>
<lang> OR <framework> CVE <year> <month>
<framework> security advisory <date-qualifier>
```

**Broad mode — unbounded queries (full posture review):**

No date constraints. Include historical CVE databases and advisory
sources. Run 5-6 queries for broader coverage:

```
<lang> OR <framework> CVE site:nvd.nist.gov OR site:cve.org
<dependency-1> OR <dependency-2> vulnerability OR advisory
"supply chain attack" <lang> OR <framework>
"MCP server" OR "AI agent" security vulnerability
<lang> security best practices OWASP
<framework> known vulnerabilities advisory
```

Where `<dependency-1>`, `<dependency-2>` are the highest-risk
dependencies from the repo profile (ORMs, auth libraries, HTTP
frameworks, crypto packages).

4. For each promising result (up to 8 in incremental mode, up to 12 in broad
   mode), use WebFetch to retrieve details. Stop fetching if a result is
   paywalled, irrelevant, or a duplicate of something already in the
   knowledge base.

5. **Filter resolved threats** — cross-reference every candidate threat
   against the resolved threats list from Phase 2. If a threat matches a
   resolved entry (same CVE, same package+vulnerability, or same slug),
   **exclude it** from scoring. Note the count of filtered-out resolved
   threats for the executive summary.

**Gate:** NONE

---

## Phase 4: Score Relevance

For each threat identified (excluding resolved), score on three axes (1-5):

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

## Phase 5: Write the Brief

Run `date -u '+%Y-%m-%d %H:%M UTC'` to get the timestamp.

**Filename:** `knowledge/roles/ciso/articles/generated/<mode>-YYYY-MM-DD.md`
where `<mode>` is `incremental` or `broad`.

If a file with this name already exists, append a sequence number:
`incremental-YYYY-MM-DD-2.md`, `broad-YYYY-MM-DD-2.md`, etc. Never
refuse to run — the user may want a fresh scan.

```markdown
# CISO <Mode> Brief — YYYY-MM-DD
_Created: YYYY-MM-DD HH:MM UTC_
_Type: LLM-generated synthesis_
_Mode: <incremental | broad>_
_Time window: <since YYYY-MM-DD (N days) | unbounded>_
_Repo: <project name from CLAUDE.md>_

## Executive Summary
<2-3 sentences: top threats today, overall risk posture>
- **Threats scanned:** N
- **Included (relevance >= 2.5):** N
- **Filtered (below threshold):** N
- **Skipped (previously resolved):** N

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
<List of all URLs fetched during Phase 3, with one-line descriptions>
```

If no threats meet the relevance threshold, write a brief with:
```markdown
## Executive Summary
No threats with relevance >= 2.5 found today. N threats scanned across
<search domains>. N previously resolved threats were skipped.
Repo security posture unchanged from previous brief.
```

**Gate:** SOFT — present the brief to the user before proceeding to ingestion
and actions. The user may want to adjust scores or add context.

---

## Phase 6: Ingest High-Relevance Sources

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
   articles and the brief itself

Present a summary to the user:
- Number of threats analyzed
- Number included in brief (relevance >= 2.5)
- Number of sources ingested (relevance >= 4.0)
- Number of previously resolved threats skipped
- Top threat (highest relevance score)

**Gate:** NONE

---

## Phase 7: Propose Actions

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

## Phase 8: Update Resolved Threats

After actions are executed (or explicitly dismissed/deferred), update the
resolved threats log.

**File:** `knowledge/roles/ciso/notes/resolved-threats.md`

If the file doesn't exist, create it with this structure:

```markdown
# Resolved Threats
_Updated: YYYY-MM-DD HH:MM UTC_

Threats listed here will be excluded from future briefs.
Remove an entry to resurface it.

| Date | Threat | Resolution | Brief |
|------|--------|------------|-------|
```

**When to add entries:**

| User response | What to record |
|---------------|----------------|
| Executes an AUTO action | Add with resolution: `Remediated — <what was done>` |
| Acknowledges a MANUAL action as done | Add with resolution: `Remediated (manual) — <what>` |
| Dismisses a threat (`none` for specific items) | Add with resolution: `Dismissed — <reason from user, or "not applicable">` |
| Defers a threat | Do NOT add — deferred threats should resurface |

**Entry format:**
```
| YYYY-MM-DD | <CVE or short slug> — <one-line description> | <resolution> | <brief filename> |
```

After updating, run `date -u '+%Y-%m-%d %H:%M UTC'` and update the
`_Updated:` timestamp at the top of the file.

**Stale entries:** Resolved threats are assumed to stay resolved. If a
new variant or regression of a resolved threat appears (different CVE,
same package), it is a **new threat** and will not be filtered. The
matching in Phase 3 is by specific identifier, not by general topic.

**Gate:** NONE

---

## Rules

- **No false urgency** — if nothing relevant is found, say so clearly.
  An empty brief is better than inflated threats.
- **Cite sources** — every threat must link to its source URL
- **Repo-specific, not generic** — recommendations must reference actual
  files, dependencies, or configurations in this project
- **Faithful ingestion** — source articles saved to `external/` are faithful
  markdown conversions, never summarized
- **Timestamps** — always run `date -u` for real timestamps, never guess
- **Explicit time windows** — never rely on vague "recent" hints.
  Incremental mode computes the window from the last brief's date;
  broad mode has no time constraint. State the time window in the brief
  header.
- **Resolved threats stay resolved** — once a threat is in
  `resolved-threats.md`, it does not appear in future briefs unless the
  user manually removes it from the file
