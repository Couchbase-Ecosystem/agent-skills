# Couchbase Mobile — Agent Skills

A set of **agent skills** that provisions a Capella App Services (free-tier) backend — ready to go
with app data, users, and access-control functions — then generates a runnable app project built on
the Couchbase Lite SDK with bidirectional **cloud-to-edge** data sync: the app keeps working through
a network drop and reconciles when it reconnects.

**Both iOS (Swift) and Android (Kotlin / Jetpack Compose) are supported, stable client platforms.**
Other platforms are coming.

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
| `couchbase-lite-android-app` | Android (Kotlin / Compose) client capability |

You interact with **one** skill — the recipe. It supports **both iOS and Android**: it asks which
platform you want up front, then pulls in the others as needed and selects the matching client skill.
Don't invoke the capability skills directly.

## Prerequisites

You'll need three things for any build:

- A free **[Couchbase Capella](https://cloud.couchbase.com)** account (no credit card). The backend gets provisioned here.
- An AI coding agent to run the skills. They're built and tested on **Claude** — **Claude Code** (CLI) or **Cowork** (the desktop app). Other agents that read `SKILL.md` files, like Cursor, can load them too, but we've only tested Claude.
- **Xcode** (for iOS) or **Android Studio** (for Android), at the versions below.

The recipe always pins the newest Couchbase Lite your toolchain can run — today that's the **4.1.x** line (Enterprise Edition) on both platforms.

### iOS (Swift)

| | |
|---|---|
| Xcode | **16.0 minimum.** 16.3 or newer (including 26.x and 27.x) gets you the latest CBL 4.1.x; 16.0–16.2 pins CBL 4.0.x. Below 16.0 isn't supported. |
| Couchbase Lite Swift (EE) | 4.1.x on Xcode 16.3+, else 4.0.x |
| iOS target | 16.0 |
| Simulators | Two — the offline-sync test runs the app on both at once |

The recipe reads your Xcode version and picks the matching Couchbase Lite SDK version, so you don't have to.

### Android (Kotlin / Jetpack Compose)

| | |
|---|---|
| Android Studio | **Ladybug (2024.2.1) or newer.** Koala Feature Drop (2024.1.2) is the oldest that handles `compileSdk 35`. |
| JDK | **17 to 22.** The project's bundled Gradle (8.9) won't run on JDK 23 or later. Recent Android Studio releases bundle JDK 25, so set the Gradle JVM to 17–21 in **Settings → Build, Execution, Deployment → Build Tools → Gradle**. |
| Android SDK | API 35 installed |
| minSdk | 24 (Android 7.0), required by the CBL 4.x library |
| Gradle / AGP | Gradle 8.x, AGP 8.x |
| Kotlin | 2.0+ |
| Couchbase Lite Android (EE) | 4.1.0 |
| Emulators | Two separate AVDs for the offline-sync test |

There's no fallback for older toolchains — AGP 8 and JDK 17 are required. If Android Studio is out of date, update it; it brings a compatible JDK and AGP with it.

## Get the skills from GitHub

Clone the repo:

```bash
git clone https://github.com/Couchbase-Ecosystem/agent-skills.git
```

The six skills live in **`agent-skills/plugins/couchbase-mobile/skills/`**.

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

## Cleaning up — tearing down the backend

Done with a demo or test build? `teardown-capella.sh` (in `couchbase-appservices-provisioning/assets/`,
copied into your project alongside `setup-capella.sh`) deletes the Capella backend resources that
`setup-capella.sh` actually created — nothing more:

```bash
source provision.env && ./teardown-capella.sh
```

It prints the exact plan — what will be deleted, what will be left alone and why — and asks for one
confirmation before touching anything. It's safe to run even if you've reused a Project, Cluster, or
App Service across multiple test apps on the same free-tier account: teardown only ever deletes a
resource `setup-capella.sh` itself created (tracked automatically in `provision.env`); anything it
found already existing — and so might be shared with another app — is left completely alone.

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
