---
description: Always-on security guardrails. Loaded in every session.
---

# Security Guardrails

## Secrets

- NEVER hardcode API keys, passwords, tokens, or private keys in source files
- Verify `.env` is in `.gitignore` before any commit
- Use environment variables or a secrets manager for all credentials
- If a secret may have been exposed, alert the user immediately

## Input Validation

- Validate all user input at system boundaries
- Use parameterized queries for all database operations (no string interpolation)
- Sanitize HTML output to prevent XSS
- Validate file paths to prevent directory traversal

## Error Handling

- Error messages shown to users must NOT include stack traces, internal paths,
  or system details
- Log detailed errors server-side, show generic messages client-side
- Never silently swallow errors — handle them explicitly

## Dependencies

- Prefer well-maintained, widely-used packages over obscure alternatives
- Check for known vulnerabilities before adding new dependencies
- Pin dependency versions in lock files
