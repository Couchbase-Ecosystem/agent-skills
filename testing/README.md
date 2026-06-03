# Testing

Per-skill evaluation suites live under `testing/<skill-name>/evals/evals.json`.

Each suite defines prompts and assertions used to check that a skill triggers
correctly and produces valid Couchbase output (SQL++, index/DDL, search-index
definitions). Copy `testing/_template/evals/evals.json` to start a new suite.

## Schema

```jsonc
{
  "skill": "couchbase-<skill-name>",
  "cases": [
    {
      "name": "short description of the scenario",
      "input": "the user prompt",
      "expect": ["substrings that MUST appear in the response"],
      "reject": ["substrings that must NOT appear"],
      "threshold": 1            // optional: min count of `expect` matches required
    }
  ]
}
```

## Running

Evals that exercise a live cluster require a Couchbase Server / Capella project
with the `travel-sample` bucket loaded, plus the `CB_*` environment variables
(see the repo `README.md`). Structural validation runs without a cluster:

```bash
./tools/validate-skills.sh
```
