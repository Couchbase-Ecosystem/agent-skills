# Couchbase Mobile — Agent Skills

Couchbase Mobile agent skills let you build a fully functioning mobile app with **always-on**
data sync capability that allows the app to continue running in offline mode even with no internet
connectivity. It provisions a Capella App Services backend — ready to go with app data, users, roles,
and access-control functions — then generates a runnable app project built on the Couchbase Lite SDK
as its local database, with bidirectional **cloud-to-edge** data sync: the app keeps working through a
network drop and reconciles when it reconnects.

**Both iOS (Swift) and Android (Kotlin / Jetpack Compose) are supported, stable client platforms.**
Other platforms are coming.

> These ship as one plugin — **`couchbase-mobile`** — in this repo's `couchbase-plugins` marketplace.
> See [Install the plugin](#install-the-plugin) below.

## What's included

| Skill | Role |
|---|---|
| `couchbase-mobile-cloud-edge-sync-app` | The entry-point recipe — runs when you ask to build an app and drives the whole build |
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

## Install the plugin

The six skills ship as one plugin, **`couchbase-mobile`**, in this repo's **`couchbase-plugins`**
marketplace. Install it in your tool using the steps below, then [build an app](#build-an-app). You
only ever call the recipe — it pulls in the other skills itself.

> **Anthropic plugin directory — coming soon.** Once `couchbase-mobile` is listed in Claude's built-in
> plugin directory, you'll add it with no marketplace step (Claude Desktop: Customize → Plugins →
> search **Couchbase Mobile** → **Add**; Claude Code: browse with `/plugin`). Until then, use the
> marketplace steps below.

### Claude Code (CLI)

- Run `/plugin marketplace add Couchbase-Ecosystem/agent-skills`
- Run `/plugin install couchbase-mobile@couchbase-plugins`
- Run `/plugin` to confirm **couchbase-mobile** is installed with its six skills

### Claude Desktop — Code tab

- Open the **Code** tab
- Run `/plugin marketplace add Couchbase-Ecosystem/agent-skills`
- Run `/plugin install couchbase-mobile@couchbase-plugins`
- Run `/plugin` to confirm

### Claude Desktop — Plugins (Customize)

- Open **Customize → Plugins**
- Click **＋ → Add marketplace**, enter `Couchbase-Ecosystem/agent-skills`, click **Sync**
- Click **＋** next to **couchbase-mobile** to install it
- Start a new session

### Cursor

- Add `Couchbase-Ecosystem/agent-skills` as a plugin marketplace
- Install **couchbase-mobile** via `/add-plugin` or the marketplace UI

### Codex (CLI)

- Run `codex plugin marketplace add Couchbase-Ecosystem/agent-skills`
- Start `codex` and open `/plugins`
- Install **couchbase-mobile**

### Codex (Desktop)

- Open **Plugins**, click the dropdown next to **＋ → Add marketplace**
- Enter `Couchbase-Ecosystem/agent-skills`
- Install **Couchbase Mobile**

### GitHub Copilot (CLI)

- Run `/plugin marketplace add Couchbase-Ecosystem/agent-skills`
- Run `/plugin install couchbase-mobile@couchbase-plugins`

### Antigravity (CLI)

- Run `agy plugin install https://github.com/Couchbase-Ecosystem/agent-skills`
- Select **couchbase-mobile**

> **Local development:** to test from a clone instead of GitHub, add your working copy as the
> marketplace — in Claude Code, `/plugin marketplace add /path/to/agent-skills` (no push needed).
>
> **Gemini CLI** isn't supported for this plugin — its extension format is MCP-only, and the mobile
> plugin is skills-only.

### Build an app

Ask: **"I want to build a Couchbase Mobile app."** The recipe (`couchbase-mobile-cloud-edge-sync-app`)
takes over — it asks a couple of questions (platform, domain, access pattern), confirms your
toolchain version, and drives the build.

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
