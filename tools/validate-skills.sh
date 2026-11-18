#!/usr/bin/env bash
#
# validate-skills.sh — structural validation for Couchbase Agent Skills.
#
# Checks every skill — the core plugin's skills/<name>/SKILL.md and each
# bundled plugin's plugins/<plugin>/skills/<name>/SKILL.md — for:
#   - presence of a YAML frontmatter block
#   - required frontmatter fields: name, description
#   - name matches the containing directory
#   - SKILL.md size (warn > 500 lines, fail > 800 lines)
#
# Exit code: 0 = pass, 1 = one or more failures. Directories beginning with
# "_" (e.g. _template) are skipped.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Every skill root in the repo: the core plugin plus each bundled plugin.
# New plugins under plugins/ are picked up automatically.
SKILL_ROOTS=("$ROOT/skills")
for plugin_skills in "$ROOT"/plugins/*/skills; do
  [[ -d "$plugin_skills" ]] && SKILL_ROOTS+=("$plugin_skills")
done

fail=0
warn=0
count=0

skill_mds=()
for root in "${SKILL_ROOTS[@]}"; do
  skill_mds+=("$root"/*/SKILL.md)
done

for skill_md in "${skill_mds[@]}"; do
  [[ -e "$skill_md" ]] || continue
  skill_dir="$(dirname "$skill_md")"
  dir="$(basename "$skill_dir")"
  case "$dir" in _*) continue ;; esac
  # Label failures with the repo-relative path so plugin skills are findable.
  label="${skill_dir#"$ROOT"/}"
  count=$((count + 1))

  # Frontmatter must start on line 1 with '---'
  if [[ "$(head -n 1 "$skill_md")" != "---" ]]; then
    echo "FAIL [$label] missing YAML frontmatter (must start with '---')"
    fail=$((fail + 1))
    continue
  fi

  # Extract the frontmatter block (between the first two '---' lines)
  fm="$(awk 'NR>1 && /^---[[:space:]]*$/{exit} NR>1{print}' "$skill_md")"

  name_val="$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -n1 | tr -d '"' | tr -d "'" | xargs 2>/dev/null)"
  if [[ -z "$name_val" ]]; then
    echo "FAIL [$label] frontmatter missing 'name'"
    fail=$((fail + 1))
  elif [[ "$name_val" != "$dir" ]]; then
    echo "FAIL [$label] frontmatter name '$name_val' does not match directory"
    fail=$((fail + 1))
  fi

  if ! printf '%s\n' "$fm" | grep -qE '^description:'; then
    echo "FAIL [$label] frontmatter missing 'description'"
    fail=$((fail + 1))
  fi

  lines="$(wc -l < "$skill_md" | xargs)"
  if (( lines > 800 )); then
    echo "FAIL [$label] SKILL.md is $lines lines (>800)"
    fail=$((fail + 1))
  elif (( lines > 500 )); then
    echo "WARN [$label] SKILL.md is $lines lines (>500)"
    warn=$((warn + 1))
  fi
done

echo "---"
echo "Validated $count skill(s): $fail failure(s), $warn warning(s)."
[[ $fail -eq 0 ]] || exit 1
