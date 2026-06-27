#!/usr/bin/env python3
"""Real-harness test runner for the Couchbase agent skills.

Drives the *real* Claude Code CLI (`claude -p ... --output-format stream-json`)
inside the sandbox container — skills installed, MCP server wired, a live
`travel-sample` cluster — and scores each eval case on three dimensions:

  1. the correct skill auto-triggered       (case "expect_skill")
  2. the expected MCP tools were called      (case "expect_tools")
  3. expect/reject substrings in the answer  (case "expect"/"reject"/"threshold")

This is the check the model-only `tools/run-evals.py` cannot do: it injects each
SKILL.md as the system prompt, so it can never observe *triggering/routing*. Only
the real CLI with skills installed surfaces a `Skill` tool_use we can detect.

Single-sourced: schema + scoring helpers are imported from tools/run-evals.py so
the test-case format stays in one place. Runs INSIDE the container (see
testing/sandbox/README.md). Pure standard library.

`--smoke` runs only the curated one-per-skill cases flagged `"smoke": true`.
"""
import argparse
import importlib.util
import json
import subprocess
import sys
import time
from pathlib import Path


def load_run_evals(repo):
    """Import tools/run-evals.py so we reuse its schema + scoring helpers."""
    path = Path(repo) / "tools" / "run-evals.py"
    spec = importlib.util.spec_from_file_location("run_evals", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def skill_from_tool_use(name, tool_input):
    """Map a tool_use block to the skill it invokes, if any.

    Claude Code surfaces a skill invocation as a tool_use named "Skill" whose
    input names the skill. The exact input key has varied across CLI versions,
    so we probe the common ones. This is the SINGLE place that encodes the
    skill-activation event shape — confirm it with `--show-stream` and adjust
    here if the real events differ.
    """
    if name in ("Skill", "skill"):
        if isinstance(tool_input, dict):
            for key in ("name", "command", "skill", "skill_name"):
                val = tool_input.get(key)
                if isinstance(val, str) and val:
                    return val
        return "Skill:unknown"
    return None


def parse_stream(text):
    """Parse newline-delimited stream-json into the bits we score on."""
    final_text, skills, tools = "", set(), set()
    is_error, saw_result = False, False
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            ev = json.loads(line)
        except json.JSONDecodeError:
            continue  # --verbose can interleave non-JSON; ignore it
        etype = ev.get("type")
        if etype == "assistant":
            for block in ev.get("message", {}).get("content", []):
                btype = block.get("type")
                if btype == "tool_use":
                    tname = block.get("name", "")
                    if tname.startswith("mcp__"):
                        tools.add(tname)
                    sk = skill_from_tool_use(tname, block.get("input", {}))
                    if sk:
                        skills.add(sk)
                elif btype == "text":
                    final_text += block.get("text", "")
        elif etype == "result":
            saw_result = True
            is_error = bool(ev.get("is_error"))
            if isinstance(ev.get("result"), str) and ev["result"]:
                final_text = ev["result"]  # canonical final answer
    return {
        "final_text": final_text,
        "skills": skills,
        "tools": tools,
        "is_error": is_error,
        "saw_result": saw_result,
    }


def run_case(case, opts):
    """Invoke the CLI for one case. Returns (parsed, note); note is set on a
    transport/exit problem worth flagging."""
    cmd = [
        "claude", "-p", case["input"],
        "--output-format", "stream-json", "--verbose",
        "--dangerously-skip-permissions",
    ]
    if not opts.github and opts.mcp_config:
        cmd += ["--mcp-config", opts.mcp_config, "--strict-mcp-config"]

    attempt = 0
    while True:
        attempt += 1
        try:
            proc = subprocess.run(
                cmd, cwd=opts.repo, capture_output=True, text=True,
                timeout=opts.timeout)
        except subprocess.TimeoutExpired:
            return None, f"timed out after {opts.timeout}s"

        if opts.show_stream:
            sys.stderr.write(f"\n----- raw stream for {case['name']!r} -----\n")
            sys.stderr.write(proc.stdout + "\n")
            sys.stderr.write("----- end stream -----\n")

        parsed = parse_stream(proc.stdout)
        err = (proc.stderr or "").lower()
        rate_limited = any(s in err for s in ("rate", "overloaded", "429", "529"))
        if rate_limited and attempt <= opts.retries:
            backoff = min(60, 2 ** attempt)
            print(f"      (rate-limited; retry {attempt}/{opts.retries} in {backoff}s)")
            time.sleep(backoff)
            continue

        note = None
        if proc.returncode != 0 and not parsed["saw_result"]:
            note = f"claude exited {proc.returncode}: {proc.stderr.strip()[:200]}"
        return parsed, note


def score_case(case, parsed, run_evals):
    """Return (passed, [reasons]) checking all three dimensions."""
    reasons = []
    ans = parsed["final_text"]
    ok_sub, hits, bad = run_evals.score(
        ans, case.get("expect", []), case.get("reject", []),
        case.get("threshold", 0))
    if not ok_sub:
        thr = case.get("threshold", 0)
        if len(hits) < thr:
            missed = [t for t in case.get("expect", []) if t.lower() not in ans.lower()]
            reasons.append(f"expect {len(hits)}/{thr} (missed {missed})")
        if bad:
            reasons.append(f"hit reject {bad}")

    want_skill = case.get("expect_skill")
    if want_skill and not any(want_skill in s for s in parsed["skills"]):
        reasons.append(f"skill {want_skill!r} not triggered "
                       f"(saw {sorted(parsed['skills']) or 'none'})")

    for needle in case.get("expect_tools", []):
        if not any(needle in tn for tn in parsed["tools"]):
            reasons.append(f"tool ~{needle!r} not called "
                           f"(saw {sorted(parsed['tools']) or 'none'})")

    if parsed["is_error"]:
        reasons.append("CLI reported is_error")
    return (not reasons), reasons


def main():
    ap = argparse.ArgumentParser(description="Real-harness eval runner for the skills.")
    ap.add_argument("--repo", default="/work", help="repo root (default /work)")
    ap.add_argument("--mcp-config", dest="mcp_config",
                    help="MCP config file passed to the CLI (local mode)")
    ap.add_argument("--github", action="store_true",
                    help="skills/MCP come from the installed plugin (omit --mcp-config)")
    ap.add_argument("--smoke", action="store_true",
                    help="run only cases flagged \"smoke\": true (ignores tier bounds)")
    ap.add_argument("--scenarios", action="store_true",
                    help="run the broader curated set: cases flagged \"smoke\" OR "
                         "\"scenario\": true (ignores tier bounds)")
    ap.add_argument("--skill", help="run only this skill's suite")
    ap.add_argument("--skip-skill", action="append", default=[], dest="skip_skills",
                    help="exclude this skill's suite (repeatable)")
    ap.add_argument("--case", help="run only cases whose name contains this substring")
    ap.add_argument("--tier-min", type=int, default=2)
    ap.add_argument("--tier-max", type=int, default=3)
    ap.add_argument("--timeout", type=int, default=300, help="per-case seconds")
    ap.add_argument("--retries", type=int, default=3, help="rate-limit retries")
    ap.add_argument("--show-stream", action="store_true",
                    help="dump raw stream-json to stderr (confirm event shapes)")
    opts = ap.parse_args()

    run_evals = load_run_evals(opts.repo)
    suites = run_evals.discover_suites(opts.skill)
    if not suites:
        target = f" for '{opts.skill}'" if opts.skill else ""
        print(f"No eval suites found{target}.")
        return 1

    if opts.smoke:
        selection = "smoke cases"
    elif opts.scenarios:
        selection = "scenario cases (smoke + scenario)"
    else:
        selection = f"tiers {opts.tier_min}-{opts.tier_max}"
    print(f"Repo: {opts.repo} | install: {'github' if opts.github else 'local'} "
          f"| selecting: {selection}")

    n_pass = n_fail = n_err = 0
    executed = 0

    for suite_name, path in suites:
        if suite_name in opts.skip_skills:
            print(f"SKIP  {suite_name}: --skip-skill")
            continue
        data = json.loads(Path(path).read_text())
        problems = run_evals.validate_suite(data)
        if problems:
            print(f"SKIP  {suite_name}: invalid schema — run tools/run-evals.py --dry-run")
            n_err += 1
            continue

        header_printed = False
        for case in data["cases"]:
            if opts.smoke:
                if not case.get("smoke"):
                    continue
            elif opts.scenarios:
                if not (case.get("smoke") or case.get("scenario")):
                    continue
            else:
                tier = case.get("tier", 2)
                if tier < opts.tier_min or tier > opts.tier_max:
                    continue
            if opts.case and opts.case not in case["name"]:
                continue

            if not header_printed:
                print(f"\n=== {suite_name} ===")
                header_printed = True

            executed += 1
            parsed, note = run_case(case, opts)
            if parsed is None:
                n_err += 1
                print(f"  ERROR {case['name']}  — {note}")
                continue

            passed, reasons = score_case(case, parsed, run_evals)
            if note:
                reasons.append(note)
            triggered = sorted(parsed["skills"]) or ["none"]
            called = sorted(t.replace("mcp__couchbase__", "") for t in parsed["tools"]) or ["none"]
            if passed:
                n_pass += 1
                print(f"  PASS  {case['name']}  [skill {triggered}, tools {called}]")
            else:
                n_fail += 1
                print(f"  FAIL  {case['name']}  — {'; '.join(reasons)}")

    if executed == 0:
        what = "smoke" if opts.smoke else "scenario" if opts.scenarios else "matching"
        print(f"\nNo {what} cases selected — nothing to run.")
        return 1

    print("\n---")
    print(f"{n_pass} passed, {n_fail} failed, {n_err} errored.")
    return 0 if (n_fail == 0 and n_err == 0) else 1


if __name__ == "__main__":
    sys.exit(main())
