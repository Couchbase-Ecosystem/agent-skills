#!/usr/bin/env bash
#
# validate-skills.sh — structural validation for Couchbase Agent Skills.
#
# Checks each skills/<name>/SKILL.md for:
#   - presence of a YAML frontmatter block
#   - required frontmatter fields: name, description
#   - name matches the containing directory
#   - SKILL.md size (warn > 500 lines, fail > 800 lines)
#
# Exit code: 0 = pass, 1 = one or more failures. Directories beginning with
# "_" (e.g. _template) are skipped.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$ROOT/skills"

fail=0
warn=0
count=0

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "No skills/ directory found at $SKILLS_DIR"
  exit 0
fi

for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
  [[ -e "$skill_md" ]] || continue
  dir="$(basename "$(dirname "$skill_md")")"
  case "$dir" in _*) continue ;; esac
  count=$((count + 1))

  # Frontmatter must start on line 1 with '---'
  if [[ "$(head -n 1 "$skill_md")" != "---" ]]; then
    echo "FAIL [$dir] missing YAML frontmatter (must start with '---')"
    fail=$((fail + 1))
    continue
  fi

  # Extract the frontmatter block (between the first two '---' lines)
  fm="$(awk 'NR>1 && /^---[[:space:]]*$/{exit} NR>1{print}' "$skill_md")"

  name_val="$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -n1 | tr -d '"' | tr -d "'" | xargs 2>/dev/null)"
  if [[ -z "$name_val" ]]; then
    echo "FAIL [$dir] frontmatter missing 'name'"
    fail=$((fail + 1))
  elif [[ "$name_val" != "$dir" ]]; then
    echo "FAIL [$dir] frontmatter name '$name_val' does not match directory"
    fail=$((fail + 1))
  fi

  if ! printf '%s\n' "$fm" | grep -qE '^description:'; then
    echo "FAIL [$dir] frontmatter missing 'description'"
    fail=$((fail + 1))
  fi

  lines="$(wc -l < "$skill_md" | xargs)"
  if (( lines > 800 )); then
    echo "FAIL [$dir] SKILL.md is $lines lines (>800)"
    fail=$((fail + 1))
  elif (( lines > 500 )); then
    echo "WARN [$dir] SKILL.md is $lines lines (>500)"
    warn=$((warn + 1))
  fi
done

echo "---"
echo "Validated $count skill(s): $fail failure(s), $warn warning(s)."
[[ $fail -eq 0 ]] || exit 1
