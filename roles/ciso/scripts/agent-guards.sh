#!/usr/bin/env zsh
# Soft guardrails for Claude-driven shells.
#
# Sourced from ~/.zshenv. Gated on $CLAUDECODE so non-Claude shells are
# unaffected. Override common commands that an enthusiastic agent might use to
# scrape secrets from the shell environment, replacing them with friendly
# refusals that ask the user to provide specific values when needed.
#
# This is NOT cybersecurity-grade. A determined agent can bypass it by
# invoking command paths directly or via subshells. The point is to raise
# the floor against accidental exposure, not to enforce a hard boundary.
#
# Source: derived from Dean Langsam's pattern.
# Threat model: ./reference/threat-model.md (in the install-agent-guards skill)

[[ -n "$CLAUDECODE" ]] || return 0

# 1. env: show variable names, not values
env() {
  command env | sed 's/=.*$//' | sort
  echo ""
  echo "(agent-guards: variable values hidden. If you need a specific value, name it,"
  echo " explain why, and ask the user.)"
}

# 2. printenv: block well-known sensitive names; pass through everything else
#
# Project-specific extensions: copy this script to ~/.agent_guards.sh and add
# project-specific token patterns (e.g., "FOO_API_*|BAR_TOKEN") to the case
# branch below. The suffix patterns at the end (*_TOKEN, *_API_KEY, etc.)
# already cover most naming conventions generically.
printenv() {
  local v="$1"
  case "$v" in
    ANTHROPIC_API_KEY|OPENAI_API_KEY|GOOGLE_API_KEY|GH_TOKEN|GITHUB_TOKEN|\
    AWS_*|GCP_*|AZURE_*|\
    *_SECRET|*_PRIVATE_KEY|*_PASSWORD|*_PASSPHRASE|*_TOKEN|*_API_KEY)
      echo "(agent-guards: $v is sensitive. Ask the user to provide the value if needed.)"
      return 1
      ;;
    *)
      command printenv "$@"
      ;;
  esac
}

# 3. cat on .env or credentials files: refuse politely
cat() {
  local arg
  for arg in "$@"; do
    case "$arg" in
      *.env|.env|.env.*|*credentials*|*secrets*|*.pem|*.key)
        echo "(agent-guards: $arg likely contains secrets. Ask the user for the specific value.)"
        return 1
        ;;
    esac
  done
  command cat "$@"
}

# 4. gh auth token: block (full repo+workflow scope; CISO rule mandates rotation)
gh() {
  if [[ "$1" == "auth" && "$2" == "token" ]]; then
    echo "(agent-guards: gh auth token is blocked. Ask the user if you genuinely need it.)"
    return 1
  fi
  command gh "$@"
}

# 5. Generic dotfile read warning
__agent_guards_warn_dotfile() {
  case "$1" in
    *.aws/credentials|*.config/gh/hosts.yml|*.netrc|*.npmrc|*.pypirc)
      echo "(agent-guards: $1 likely contains credentials. Ask the user before reading.)" >&2
      return 1
      ;;
  esac
  return 0
}
