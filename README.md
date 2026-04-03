# soloforge-crew

**Ready-to-use specialist roles for Claude Code.**

Drop-in agents, rules, skills, and knowledge for solo developers and small
teams using Claude Code. Each role is self-contained — install only what you
need.

---

## Available Roles

| Role | What it does | Status |
|------|-------------|--------|
| **ciso** | Daily threat intel, security review, guardrails | Available |
| **red-team** | Adversarial review with structured scorecard | Coming soon |

---

## Install

```bash
# Clone once
git clone https://github.com/ylazar/soloforge-crew.git ~/soloforge-crew

# Install a role into your project
~/soloforge-crew/install.sh ciso

# Install to a specific project
~/soloforge-crew/install.sh ciso ~/my-project

# Install all available roles
~/soloforge-crew/install.sh --all
```

### What gets installed

For the **ciso** role:
- `.claude/agents/ciso.md` — security reviewer subagent
- `.claude/rules/ciso/security-guardrails.md` — always-on security rules
- `.claude/skills/threat-intel/SKILL.md` — daily security brief skill
- `knowledge/roles/ciso/` — knowledge directory with security priority sources

### Update

```bash
cd ~/soloforge-crew && git pull
~/soloforge-crew/install.sh ciso ~/my-project
```

Existing customizations are not overwritten — the installer skips files you've modified.

---

## Usage

### Daily security brief

Run `/threat-intel` at the start of your work day. It will:

1. **Profile your repo** — languages, dependencies, MCP servers, agent tools
2. **Scan threat feeds** — CVE databases, supply chain attack reports, AI security research
3. **Score relevance** — each threat scored on applicability, severity, and proximity to your specific project
4. **Write a brief** — saved to `knowledge/roles/ciso/articles/generated/<mode>-YYYY-MM-DD.md`
5. **Propose actions** — classified as AUTO (agent can execute) or MANUAL (you need to act), with your approval before anything runs

### Security review

Spawn the CISO agent to review code changes:
```
spawn ciso agent to review the changes in this PR
```

### Disable the daily nudge

If you use soloforge's `/proceed` skill, it will nudge you to run `/threat-intel` if no brief exists for today. To disable:

Create `knowledge/roles/ciso/config.yaml`:
```yaml
daily-brief: disabled
```

---

## Works with soloforge

soloforge-crew roles work **standalone** in any Claude Code project.

If you also use [soloforge](https://github.com/ylazar/soloforge), the roles
integrate seamlessly — soloforge's `/proceed` skill detects the CISO role and
suggests running `/threat-intel` daily.

---

## Customize

Each role's agent definition and knowledge base are meant to be customized
for your domain. The installed files are yours — edit freely.

- **Agent prompt**: `.claude/agents/ciso.md` — adjust review focus areas
- **Security rules**: `.claude/rules/ciso/security-guardrails.md` — add project-specific rules
- **Priority sources**: `knowledge/roles/ciso/knowledge/priority-sources.md` — add your trusted security feeds
- **Knowledge base**: `knowledge/roles/ciso/articles/` — grows automatically as `/threat-intel` ingests sources

---

## Contributing

Want to add a role? Each role is a self-contained directory under `roles/`:

```
roles/<name>/
  README.md              # What the role does, when to use it
  agent.md               # Agent definition (YAML frontmatter + markdown)
  rules/                 # Optional always-on rules
  skills/                # Optional skills
  knowledge/             # Starter knowledge and priority sources
```

---

## License

MIT
