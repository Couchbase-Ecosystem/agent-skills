## Capella Backend Setup — Automated (Recommended)

> ⚠️ **This script provisions a FREE TIER Capella backend only.** It is designed for mobile development and testing. Free tier provides 1 node, 10 GB storage, and automatically turns off after 72 hours of inactivity. For production, use a paid Capella cluster. Always make this clear to the user before running the script.

The entire backend — cluster, bucket, App Service, App Endpoint, Access Control Functions, roles, and default users — can be provisioned with a single script.

> **When copying or writing `setup-capella.sh`**: always run `chmod +x setup-capella.sh` immediately after creating the file so it is executable. Do this automatically — never make the user do it manually.

> ⏱ Free-tier provisioning takes 20–45 minutes total. The script polls and waits automatically.

### Prerequisites

- A **bash shell** with **`curl`** and **`jq`** (the script is `#!/usr/bin/env bash` and uses bash features — it does **not** run in Windows `cmd`/PowerShell directly):
  - **macOS:** bash + curl built in; `brew install jq`. (iOS devs are on macOS.)
  - **Linux:** bash + curl built in; `sudo apt install jq` (or `dnf install jq`).
  - **Windows:** run it under **WSL** (recommended) or **Git Bash** — not `cmd`/PowerShell. Install jq (`sudo apt install jq` in WSL, or `winget install jqlang.jq` for Git Bash). This matters for future Android/web clients whose devs may be on Windows.
- A **free Capella account** — sign up at https://cloud.couchbase.com (no credit card needed)
- A **Capella API key with the Organization Owner role**:
  Capella UI → select your **Organization** → **Settings** → **API Keys** → **Generate Key** → enter a Key Name → under **Organization Roles** check **Organization Owner** (leave other roles, the 180-day expiration, and Allowed IP Addresses at defaults) → **Generate** → **copy or download the key** (it's shown only once in the UI, so download it to be safe). The value for `CB_API_KEY` is the **`APIKeyToken`** field in the downloaded file (shown as **API Secret** in the Capella UI)

> ⚠️ Copy or download the API key secret immediately — it's shown only once and cannot be retrieved after you leave the page.

### Set up the backend -- hand the user the steps to run the script

The only thing that requires the user is a **Capella API key** (and an admin password). Everything else is automated. Prepare the files, then **hand the user the numbered steps to run the script themselves** -- do **not** run `setup-capella.sh` for them, and never ask them to paste their API key into the chat. Their key stays on their machine.

**Step 1 — prepare the files.** Copy `setup-capella.sh` into the project (`chmod +x`), and generate `provision.env` from `assets/provision.env.example` with the app-specific values (`CB_ENDPOINT_NAME`, `COLLECTIONS`, `SYNC_FUNCTIONS_DIR`) filled to match the app.

> **PRECONDITION — the Access Control Function files must already exist.** The script *uploads* one function per collection and **FATALs** (`Access Control Function not found at: …`) if any is missing — it does **not** create them. Before running, verify that for **every** entry in `COLLECTIONS` there is a file `"$SYNC_FUNCTIONS_DIR/<collection>-sync-function.js"` on disk (filenames must match the collection names). If any is missing, generate it first with **`couchbase-mobile-access-control-function`**, and make sure `SYNC_FUNCTIONS_DIR` points at the folder that actually contains them.

**Step 2 — guide the user to create a Capella API key** (present as a numbered list):
> 1. In the Capella console, select your **Organization**, then **Settings → API Keys → Generate Key**.
> 2. Enter a **Key Name**.
> 3. Under **Organization Roles**, check **Organization Owner**. Leave the other roles, the 180-day expiration, and Allowed IP Addresses at their defaults.
> 4. Click **Generate**, then **copy or download the key** (download it to be safe) — it's shown only once and can't be retrieved after you leave the page.

**Step 3 -- hand the user the steps to run it themselves.** Claude leaves `provision.env` ready with the app values filled; the user adds the two secrets and runs the script. Present it as a numbered list:
> 1. Open `provision.env` in the project folder; open the downloaded key file and copy the **`APIKeyToken`** value (shown as **API Secret** in the Capella UI) into `CB_API_KEY=''` and (optionally) set `APPSVC_ADMIN_PASS` (preset `Password1!` for dev). App values (endpoint, collections, `SYNC_FUNCTIONS_DIR`) are already filled in.
> 2. From the project folder, run `source provision.env && ./setup-capella.sh`.
> 3. It runs ~20-45 min; tell Claude when the App Endpoint is Online.

**Never run the script for the user, and never ask them to paste their API key into the chat -- the key stays on their machine.**

The command the user runs is:
```bash
source provision.env && ./setup-capella.sh
```

Run it from a **bash shell** — the same command works on macOS, Linux, and Windows-under-WSL/Git-Bash. It does **not** run in Windows `cmd`/PowerShell (`source` and `./script.sh` are bash syntax; from PowerShell you'd open WSL/Git Bash first, or use `bash setup-capella.sh` after `set -a; . ./provision.env; set +a`).

It fully automates the backend — no manual UI steps: creates the cluster/bucket/collections, App Service + App Endpoint, uploads the Access Control Functions, creates the Admin Credential, opens network access, brings the endpoint Online, and creates default App Roles/Users. The final Info.plist step is **iOS/macOS-only** (uses `plutil`); on Linux/Windows or for non-iOS clients it's skipped and the script instead **prints the WSS URL** for you to put in your client config. The core provisioning is fully cross-platform.

> **Long-running (20-45 min)** -- the script polls and waits. The user runs it in their own terminal and tells you when the endpoint is Online.
>
> The user's shell needs network access to Capella. The final `Info.plist` step uses macOS `plutil` (iOS only); on Linux/Windows or non-iOS clients the script skips it and prints the WSS URL for the user to paste into their client config instead.

### After the script: only 1 thing left

The script already writes the WSS URL into your app's `Info.plist` (`AppServicesEndpointURL`) automatically — no manual paste. So:

1. Build and run your iOS app — sign in as `bob` / `Password1!` to test. (If the script couldn't locate `Info.plist`, set `AppServicesEndpointURL` there manually — see `couchbase-lite-ios-app`.)

### Manual setup (fallback)

If you prefer the UI or the script doesn't work for your org configuration:

1. Sign up at https://cloud.couchbase.com
2. Create a free-tier cluster (any region)
3. Create a bucket, then your collections under a named scope (never `_default`)
4. Create an App Service → wait for healthy (5–25 min)
5. Create an App Endpoint → link bucket + collections
6. Configure the Access Control Function for each collection
7. Create App Services Admin Credentials (Settings → Admin Credentials)
8. Create App Users and App Roles via the Admin REST API
9. Copy the endpoint URL from the Connect tab: `wss://xxx.apps.cloud.couchbase.com:4984/<endpoint-name>`

---

