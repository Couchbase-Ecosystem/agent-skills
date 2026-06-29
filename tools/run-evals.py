#!/usr/bin/env python3
"""Run Couchbase Agent Skill eval suites (testing/<skill>/evals/evals.json).

Modes:
  --dry-run   Validate each suite's schema and list its cases. No network calls.
              Deterministic and free — safe to run on every PR. (default)
  --execute   Send each skill's SKILL.md as the system prompt plus the case
              `input` to a model, then score the response against the
              expect/reject substrings. Each case is retried up to MAX_ATTEMPTS
              times and passes on the first attempt that scores, so a transient
              sampling/serving miss doesn't fail the run — only a consistent miss
              across all attempts does.

Tiers (per-case optional `tier` field, default 2):
  2  model-only — observable from a single skill + prompt (the default).
  3  needs the real harness — cross-skill routing/deferral, or live MCP/cluster
     grounding (run real queries / EXPLAIN). NOT observable in this isolated,
     tool-less runner, so `--execute` SKIPS tier-3 cases unless you pass
     `--tier 3` (they will not pass here until a real-harness runner exists).

Providers (--execute): Anthropic or OpenAI, auto-detected from whichever API key
is set (ANTHROPIC_API_KEY or OPENAI_API_KEY), or forced with --provider.

NOTE: these skills target Claude harnesses. Scoring against OpenAI is a useful
proxy for catching gross issues, not a production-fidelity test.

Pure standard library — no pip install required.
"""
import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = REPO_ROOT / "skills"
TESTING_DIR = REPO_ROOT / "testing"
MAX_TOKENS = 2048
TEMPERATURE = 0  # deterministic-as-possible scoring; cuts run-to-run flakiness
                 # (note: reasoning models like gpt-5/o-series reject temperature != 1)
MAX_ATTEMPTS = 3  # retry a failed/errored case up to this many times; a case passes
                  # on the first attempt that scores. Absorbs transient sampling /
                  # serving non-determinism so a one-off miss doesn't fail the run.
RETRY_TEMPERATURE = 0.5  # attempt 1 stays at TEMPERATURE for a deterministic baseline;
                         # retries resample slightly hotter so a transient phrasing
                         # miss can recover (rejects are domain terms, so this is safe).

PROVIDERS = {
    "anthropic": {
        "env": "ANTHROPIC_API_KEY",
        "url": "https://api.anthropic.com/v1/messages",
        "default_model": "claude-sonnet-4-6",
    },
    "openai": {
        "env": "OPENAI_API_KEY",
        "url": "https://api.openai.com/v1/chat/completions",
        "default_model": "gpt-4o-mini",
    },
}


def discover_suites(skill=None):
    suites = []
    for path in sorted(TESTING_DIR.glob("*/evals/evals.json")):
        name = path.parent.parent.name
        if name.startswith("_"):
            continue
        if skill and name != skill:
            continue
        suites.append((name, path))
    return suites


def validate_suite(data):
    """Return a list of schema problems (empty list == valid)."""
    problems = []
    if not isinstance(data.get("skill"), str):
        problems.append("missing/invalid 'skill'")
    cases = data.get("cases")
    if not isinstance(cases, list) or not cases:
        problems.append("missing/empty 'cases'")
        return problems
    for i, c in enumerate(cases):
        tag = f"case[{i}] {c.get('name', '?')!r}"
        for field, typ in (("name", str), ("input", str),
                           ("expect", list), ("reject", list), ("threshold", int)):
            if not isinstance(c.get(field), typ):
                problems.append(f"{tag}: missing/invalid '{field}'")
        expect, threshold = c.get("expect"), c.get("threshold")
        if isinstance(expect, list) and isinstance(threshold, int):
            if threshold < 0 or threshold > len(expect):
                problems.append(
                    f"{tag}: threshold {threshold} > expect count {len(expect)} "
                    f"(impossible to pass)")
        if "tier" in c and c["tier"] not in (2, 3):
            problems.append(f"{tag}: invalid 'tier' {c['tier']!r} (expected 2 or 3)")
        # Optional real-harness fields (consumed by testing/sandbox/run-tests.py).
        # Validate their types if present so a typo'd field can't silently make a
        # case un-checkable (which would read as a false pass).
        if "smoke" in c and not isinstance(c["smoke"], bool):
            problems.append(f"{tag}: 'smoke' must be true/false")
        if "scenario" in c and not isinstance(c["scenario"], bool):
            problems.append(f"{tag}: 'scenario' must be true/false")
        if "expect_skill" in c and not isinstance(c["expect_skill"], str):
            problems.append(f"{tag}: 'expect_skill' must be a string")
        if "expect_tools" in c and not isinstance(c["expect_tools"], list):
            problems.append(f"{tag}: 'expect_tools' must be a list")
        # Elements of these list fields are matched as substrings / tool-name needles
        # (str.lower(), `needle in name`), so a non-string element passes the list
        # checks above but TypeErrors at runtime. Require list-of-strings.
        for field in ("expect", "reject", "expect_tools"):
            val = c.get(field)
            if isinstance(val, list) and not all(isinstance(x, str) for x in val):
                problems.append(f"{tag}: '{field}' must be a list of strings")
    return problems


def _post(url, headers, payload):
    req = urllib.request.Request(
        url, data=json.dumps(payload).encode("utf-8"), method="POST", headers=headers)
    with urllib.request.urlopen(req, timeout=120) as resp:
        return json.loads(resp.read().decode("utf-8"))


def call_model(provider, system, user, model, api_key, temperature=TEMPERATURE):
    """Return the model's text response. Raises on transport/API error."""
    if provider == "anthropic":
        payload = _post(PROVIDERS["anthropic"]["url"], {
            "x-api-key": api_key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        }, {
            "model": model,
            "max_tokens": MAX_TOKENS,
            "temperature": temperature,
            "system": system,
            "messages": [{"role": "user", "content": user}],
        })
        return "".join(b.get("text", "") for b in payload.get("content", [])
                       if b.get("type") == "text")
    # openai
    payload = _post(PROVIDERS["openai"]["url"], {
        "Authorization": f"Bearer {api_key}",
        "content-type": "application/json",
    }, {
        "model": model,
        "max_tokens": MAX_TOKENS,
        "temperature": temperature,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": user},
        ],
    })
    return (payload.get("choices") or [{}])[0].get("message", {}).get("content") or ""


def score(response, expect, reject, threshold):
    low = response.lower()
    hits = [t for t in expect if t.lower() in low]
    bad = [t for t in reject if t.lower() in low]
    return (len(hits) >= threshold and not bad), hits, bad


def run_dry(suites):
    ok = True
    for name, path in suites:
        data = json.loads(path.read_text())
        problems = validate_suite(data)
        if problems:
            ok = False
            print(f"FAIL  {name}: {len(problems)} schema problem(s)")
            for p in problems:
                print(f"        - {p}")
        else:
            tier3 = sum(1 for c in data["cases"] if c.get("tier", 2) == 3)
            extra = f" ({tier3} tier-3)" if tier3 else ""
            print(f"ok    {name}: {len(data['cases'])} case(s){extra}")
    print("---")
    print("Schema valid." if ok else "Schema problems found.")
    return 0 if ok else 1


def run_execute(suites, provider, model, api_key, max_tier, show_failures=False):
    n_pass = n_fail = n_err = n_skip = 0
    print(f"Provider: {provider} | model: {model} | max tier: {max_tier}")
    for name, path in suites:
        data = json.loads(path.read_text())
        if validate_suite(data):
            print(f"SKIP  {name}: invalid schema — run --dry-run")
            n_err += 1
            continue
        skill_md = SKILLS_DIR / name / "SKILL.md"
        if not skill_md.exists():
            print(f"SKIP  {name}: skills/{name}/SKILL.md not found")
            n_err += 1
            continue
        system = skill_md.read_text()
        print(f"\n=== {name} ===")
        for c in data["cases"]:
            if c.get("tier", 2) > max_tier:
                n_skip += 1
                continue
            # Try up to MAX_ATTEMPTS times: substring scoring over live model output
            # is non-deterministic (sampling + serving jitter even at temperature 0),
            # so a transient phrasing miss or API hiccup shouldn't fail the case. Pass
            # on the first attempt that scores; if none do, report the last graded one.
            passed, attempt = False, 0
            # graded_resp = the last response we actually scored (stays None until a
            # call succeeds). A retry that *errors* never overwrites it, so an earlier
            # attempt that returned a gradeable — but failing — response is still
            # reported as a real FAIL; ERROR is reserved for "no attempt ever returned
            # anything to grade". last_err carries the most recent attempt's error (if
            # the final attempt errored) so it can be surfaced rather than swallowed.
            graded_resp = last_err = None
            hits, bad = [], []
            for attempt in range(1, MAX_ATTEMPTS + 1):
                temp = TEMPERATURE if attempt == 1 else RETRY_TEMPERATURE
                try:
                    resp = call_model(provider, system, c["input"], model, api_key, temp)
                except urllib.error.HTTPError as e:
                    last_err = f"HTTP {e.code} {e.read().decode('utf-8', 'replace')[:200]}"
                    continue
                except Exception as e:  # noqa: BLE001 - report and continue
                    last_err = str(e)
                    continue
                last_err = None
                graded_resp = resp
                passed, hits, bad = score(resp, c["expect"], c["reject"], c["threshold"])
                if passed:
                    break
            tries = f" (after {attempt} attempt(s))" if attempt > 1 else ""
            if passed:
                n_pass += 1
                print(f"  PASS  {c['name']}  ({len(hits)}/{c['threshold']} expect){tries}")
            elif graded_resp is None:  # every attempt errored — nothing to score
                n_err += 1
                print(f"  ERROR {c['name']}: {last_err}{tries}")
            else:
                n_fail += 1
                bits = []
                if len(hits) < c["threshold"]:
                    missed = [t for t in c["expect"] if t.lower() not in graded_resp.lower()]
                    bits.append(f"{len(hits)}/{c['threshold']} expect (missed: {missed})")
                if bad:
                    bits.append(f"hit reject: {bad}")
                if last_err:  # graded an earlier attempt, but a later retry errored
                    bits.append(f"later retry errored: {last_err}")
                print(f"  FAIL  {c['name']}  — {'; '.join(bits)}{tries}")
                if show_failures:
                    print(f"        ↳ {' '.join(graded_resp.split())[:500]}…")
    print("\n---")
    skipped = f", {n_skip} skipped (tier > {max_tier})" if n_skip else ""
    print(f"{n_pass} passed, {n_fail} failed, {n_err} errored{skipped}.")
    return 0 if (n_fail == 0 and n_err == 0) else 1


def resolve_provider(explicit):
    """Return (provider, api_key) for --execute, or exit with a clear message."""
    if explicit:
        key = os.environ.get(PROVIDERS[explicit]["env"])
        if not key:
            sys.exit(f"{PROVIDERS[explicit]['env']} is not set — required for --provider {explicit}.")
        return explicit, key
    for provider in ("anthropic", "openai"):  # prefer Anthropic if both set
        key = os.environ.get(PROVIDERS[provider]["env"])
        if key:
            return provider, key
    sys.exit("Set ANTHROPIC_API_KEY or OPENAI_API_KEY (or pass --provider) for --execute.")


def main():
    ap = argparse.ArgumentParser(description="Run Couchbase skill eval suites.")
    ap.add_argument("--skill", help="run only this skill's suite")
    mode = ap.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true",
                      help="validate schema + list cases, no API (default)")
    mode.add_argument("--execute", action="store_true",
                      help="call the model and score responses")
    ap.add_argument("--provider", choices=sorted(PROVIDERS),
                    help="force a provider (default: auto-detect from the API key set)")
    ap.add_argument("--model", help="model id (default: the provider's default)")
    ap.add_argument("--tier", type=int, default=2,
                    help="max tier to execute (default 2; 3 includes cases needing "
                         "the real harness/cluster — they will not pass in this runner)")
    ap.add_argument("--show-failures", action="store_true",
                    help="print the model response for each FAIL (to diagnose/tune expects)")
    args = ap.parse_args()

    suites = discover_suites(args.skill)
    if not suites:
        target = f" for '{args.skill}'" if args.skill else ""
        print(f"No eval suites found{target}.")
        return 1

    if args.execute:
        provider, api_key = resolve_provider(args.provider)
        model = args.model or PROVIDERS[provider]["default_model"]
        return run_execute(suites, provider, model, api_key, args.tier, args.show_failures)
    return run_dry(suites)


if __name__ == "__main__":
    sys.exit(main())
