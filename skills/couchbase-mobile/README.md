# Couchbase Mobile — Agent Skills

A set of **agent skills** that provisions a Capella App Services (free-tier) backend — ready to go
with app data, users, and access-control functions — then generates a runnable app project built on
the Couchbase Lite SDK with bidirectional **cloud-to-edge** data sync: the app keeps working through
a network drop and reconciles when it reconnects.

**iOS (Swift) is the stable path. Android (Kotlin / Jetpack Compose) is newly added and _experimental_.**
Other platforms are coming.

> ⚠️ **Android support is experimental.** The iOS path is well-tested end to end; Android was
> added recently and is still being hardened — expect the occasional rough edge, and please file
> issues for anything you hit. For the smoothest first run, start with iOS.

> These are **skills**, used directly — no plugin required. (A one-command plugin install is planned
> once testing wraps; see the end.)

## What's included

| Skill | Role |
|---|---|
| `couchbase-mobile-cloud-edge-sync-app` | **Start here** — the recipe that drives the whole build |
| `couchbase-mobile-concepts-patterns` | Concepts: scopes/collections, channels, access patterns |
| `couchbase-mobile-access-control-function` | The App Services access-control (sync) function |
| `couchbase-appservices-provisioning` | Provisioning the Capella / App Services backend (`setup-capella.sh`) |
| `couchbase-lite-ios-app` | iOS (Swift) client capability |
| `couchbase-lite-android-app` | Android (Kotlin / Compose) client capability — **experimental** |

You interact with **one** skill — the recipe. It now supports **both iOS and Android**: it asks which
platform you want up front, then pulls in the others as needed and selects the matching client skill
(iOS is stable; Android is experimental). Don't invoke the capability skills directly.

## Prerequisites

Common:
- A free **[Couchbase Capella](https://cloud.couchbase.com)** account (no credit card).

For **iOS**:
- **macOS + Xcode** (the recipe checks your Xcode version and matches the Couchbase Lite SDK to it).
- At least **two iOS Simulators** (for the offline-sync test).

For **Android** _(experimental)_:
- **Android Studio** (a recent release) with the **Android SDK, API 35** installed.
- At least **two emulators** — two *separate* AVDs (for the offline-sync test).

The recipe checks your toolchain version up front and pins a compatible Couchbase Lite version
(supports **3.3.x through the latest 4.x**).

## Get the skills from GitHub

These skills currently live on the **`add-couchbase-mobile-skills`** branch (not yet merged to
`main`), so clone that branch directly:

```bash
git clone -b add-couchbase-mobile-skills https://github.com/Couchbase-Ecosystem/agent-skills.git
```

Already have the repo cloned? Just fetch and switch to the branch:

```bash
git fetch origin add-couchbase-mobile-skills
git checkout add-couchbase-mobile-skills
```

> Once this is merged to `main`, a plain `git clone https://github.com/Couchbase-Ecosystem/agent-skills.git` is all you need.

The six skills live in **`agent-skills/skills/couchbase-mobile/`**.

---

## Use in Claude Code (CLI)

Claude Code loads skills from a `SKILL.md` folder in your **personal** (`~/.claude/skills/`, all
projects) or **project** (`.claude/skills/`, one repo) skills directory — no plugin needed. Point
those at the six folders. Symlinks are recommended so a later `git pull` updates them in place.

**Personal (available in every project):**
```bash
cd agent-skills                 # the repo you cloned
mkdir -p "$HOME/.claude/skills" # ensure the personal skills dir exists (first time)
for s in couchbase-mobile-cloud-edge-sync-app \
         couchbase-mobile-concepts-patterns \
         couchbase-mobile-access-control-function \
         couchbase-appservices-provisioning \
         couchbase-lite-ios-app \
         couchbase-lite-android-app; do
  ln -s "$(pwd)/skills/couchbase-mobile/$s" "$HOME/.claude/skills/$s"
done
```
(Prefer a copy instead of symlinks? Swap the `ln -s` line for
`cp -R "$(pwd)/skills/couchbase-mobile/$s" "$HOME/.claude/skills/$s"`.)

**Project only (just this repo):** `mkdir -p .claude/skills` in your project, then the same loop
targeting `.claude/skills/` instead of `$HOME/.claude/skills/`.

**Verify & use:**
- Start Claude Code (`claude`). Run `/skills` — the six should be listed. (Claude Code hot-reloads
  new skills mid-session; only a brand-new top-level `~/.claude/skills/` needs a restart.)
- Then just ask: **"I want to build a Couchbase Mobile app."** The recipe
  (`couchbase-mobile-cloud-edge-sync-app`) takes over — it asks a couple of questions (platform,
  domain, access pattern), confirms your toolchain version, and drives the build.

---

## Use in Cowork (Claude desktop app)

Cowork doesn't read your local `~/.claude/skills/` — it loads the skills enabled for your
**claude.ai account** (synced into each session). So you add each skill to your account once.

1. **Make one ZIP per skill.** Each zip must have `SKILL.md` in its **top-level folder** (i.e.
   `<skill-name>/SKILL.md`). The trick is to `cd` **into** the skills directory first so the archive
   is rooted at each skill folder — zipping from the repo root nests `SKILL.md` too deep and the
   uploader rejects it.
   ```bash
   cd agent-skills/skills/couchbase-mobile     # <-- cd IN here (important)
   mkdir -p ../../skill-zips
   for s in */; do
     zip -r "../../skill-zips/${s%/}.zip" "$s" -x '*.DS_Store'
   done
   # → six zips in agent-skills/skill-zips/, each containing <skill-name>/SKILL.md at the top
   ```
2. In the desktop app, open **Customize** (sidebar) → **Skills** → the **＋** → **Create Skill** →
   **Upload a Skill**, and pick a skill's ZIP. Repeat for all six.
3. Start a **new** Cowork session (skills sync at session start) and ask **"I want to build a
   Couchbase Mobile app."** The recipe drives it from there.

> Manage or remove uploaded skills anytime under **Customize → Skills** (or on claude.ai).

---

## Coming soon — one-command install (planned)

These will **eventually** also ship as an installable **plugin** in this repo's marketplace
(`couchbase-plugins`), separate from the existing `couchbase` data plugin. That removes the manual
clone/upload for the plugin-capable surfaces. Planned experience:

- **Claude Code CLI** (and the Desktop app's **Code** tab): the plugin marketplace fetches straight
  from GitHub — no manual clone. It can even be pinned to a branch with `#<branch>`:
  ```
  /plugin marketplace add Couchbase-Ecosystem/agent-skills           # default branch
  /plugin marketplace add Couchbase-Ecosystem/agent-skills#<branch>  # a specific branch/tag
  /plugin install couchbase-mobile@couchbase-plugins
  ```
- **Cowork** (Claude desktop app): Cowork loads what's enabled on your **claude.ai account**, so once
  published you enable the plugin/skills there (Customize) and they sync into your Cowork sessions.

**Until the plugin ships, use the skills directly** (clone + point Claude Code at them, or upload the
per-skill ZIPs to your account for Cowork) — see the sections above.
