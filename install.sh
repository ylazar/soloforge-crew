#!/usr/bin/env bash
# soloforge-crew install — copy one or more roles into a Claude Code project
#
# Usage:
#   ~/soloforge-crew/install.sh ciso              # install ciso role to cwd
#   ~/soloforge-crew/install.sh ciso ~/my-project # install to specific project
#   ~/soloforge-crew/install.sh --all             # install all available roles
#   ~/soloforge-crew/install.sh --all ~/my-project
#
# Behavior:
#   - Skips files that already exist (never overwrites user customizations)
#   - Creates directories as needed
#   - Appends priority sources (doesn't overwrite existing ones)
#   - Reports what was installed

set -euo pipefail

CREW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
changed=0
skipped=0

# --- Parse arguments ---
roles=()
target=""

for arg in "$@"; do
    if [ "$arg" = "--all" ]; then
        for role_dir in "$CREW_DIR/roles"/*/; do
            [ -d "$role_dir" ] && roles+=("$(basename "$role_dir")")
        done
    elif [ -d "$arg" ]; then
        target="$arg"
    else
        roles+=("$arg")
    fi
done

# Default target is current directory
target="${target:-.}"
target="$(cd "$target" && pwd)"

if [ "${#roles[@]}" -eq 0 ]; then
    echo "Usage: $(basename "$0") <role> [<role>...] [target-dir]"
    echo "       $(basename "$0") --all [target-dir]"
    echo ""
    echo "Available roles:"
    for role_dir in "$CREW_DIR/roles"/*/; do
        [ -d "$role_dir" ] && echo "  - $(basename "$role_dir")"
    done
    exit 1
fi

# --- Helper ---
install_if_new() {
    local src="$1" dst="$2" label="$3"
    if [ -f "$dst" ]; then
        echo "    = $label (exists, skipping)"
        skipped=$((skipped + 1))
    else
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        echo "    + $label"
        changed=$((changed + 1))
    fi
}

echo "soloforge-crew: installing to $target"
echo ""

for role in "${roles[@]}"; do
    role_dir="$CREW_DIR/roles/$role"

    if [ ! -d "$role_dir" ]; then
        echo "  ? $role — not found in $CREW_DIR/roles/"
        continue
    fi

    echo "  Role: $role"

    # 1. Agent definition
    if [ -f "$role_dir/agent.md" ]; then
        install_if_new "$role_dir/agent.md" \
            "$target/.claude/agents/$role.md" \
            ".claude/agents/$role.md"
    fi

    # 2. Rules
    if [ -d "$role_dir/rules" ]; then
        for rule_file in "$role_dir/rules"/*.md; do
            [ -f "$rule_file" ] || continue
            fname="$(basename "$rule_file")"
            install_if_new "$rule_file" \
                "$target/.claude/rules/$role/$fname" \
                ".claude/rules/$role/$fname"
        done
    fi

    # 3. Skills
    if [ -d "$role_dir/skills" ]; then
        for skill_dir in "$role_dir/skills"/*/; do
            [ -d "$skill_dir" ] || continue
            skill_name="$(basename "$skill_dir")"
            if [ -f "$skill_dir/SKILL.md" ]; then
                install_if_new "$skill_dir/SKILL.md" \
                    "$target/.claude/skills/$skill_name/SKILL.md" \
                    ".claude/skills/$skill_name/SKILL.md"
            fi
        done
    fi

    # 4. Knowledge directory structure
    if [ -d "$role_dir/knowledge" ]; then
        for item in "$role_dir/knowledge"/*; do
            [ -e "$item" ] || continue
            bname="$(basename "$item")"

            if [ -d "$item" ]; then
                # Create subdirectory with .gitkeep
                mkdir -p "$target/knowledge/roles/$role/$bname"
                if [ ! -f "$target/knowledge/roles/$role/$bname/.gitkeep" ]; then
                    touch "$target/knowledge/roles/$role/$bname/.gitkeep"
                    echo "    + knowledge/roles/$role/$bname/"
                    changed=$((changed + 1))
                fi
            elif [ "$bname" = "priority-sources.md" ]; then
                # Append priority sources if they don't already exist in the
                # project's priority-sources.md
                ps_target="$target/knowledge/docs/priority-sources.md"
                if [ ! -f "$ps_target" ]; then
                    mkdir -p "$(dirname "$ps_target")"
                    echo "" >> "$ps_target"
                fi
                echo "    ~ Appending CISO priority sources to priority-sources.md"
                echo "" >> "$ps_target"
                echo "# -- $role priority sources (added by soloforge-crew) --" >> "$ps_target"
                cat "$item" >> "$ps_target"
                changed=$((changed + 1))
            else
                install_if_new "$item" \
                    "$target/knowledge/roles/$role/$bname" \
                    "knowledge/roles/$role/$bname"
            fi
        done
    fi

    # Ensure standard knowledge subdirectories exist
    for subdir in articles/external articles/generated articles/authored notes patterns; do
        dir="$target/knowledge/roles/$role/$subdir"
        mkdir -p "$dir"
        [ -f "$dir/.gitkeep" ] || touch "$dir/.gitkeep"
    done

    echo ""
done

echo "Done. $changed file(s) installed, $skipped skipped (already exist)."
echo ""
if [ "$changed" -gt 0 ]; then
    echo "Next steps:"
    echo "  1. Review installed files: git diff (or git status for new files)"
    echo "  2. Customize .claude/agents/$role.md for your project"
    echo "  3. Try: /threat-intel"
fi
echo ""
