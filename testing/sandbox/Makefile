# Dockerized sandbox for manually testing the Couchbase agent skills with the
# real Claude Code CLI. Usage: make <target>
COMPOSE := docker compose

.PHONY: help build sandbox sandbox-remote sandbox-setup sandbox-setup-remote sandbox-setup-cold clean ensure-env

help:
	@echo "Targets:"
	@echo "  build           Build the sandbox image"
	@echo "  sandbox         Fresh interactive Claude Code REPL on a local cluster (MCP pre-wired)"
	@echo "  sandbox-remote  Fresh interactive REPL against a remote cluster from .env (MCP pre-wired)"
	@echo "  sandbox-setup        REPL on a local cluster with NO MCP pre-wired — test couchbase-mcp-setup"
	@echo "  sandbox-setup-remote REPL with NO MCP pre-wired against Capella — test the Capella setup path"
	@echo "  sandbox-setup-cold   Like sandbox-setup but NO CB_* in the env either — a true first-time setup"
	@echo "  clean           Tear down containers + the local cluster volume"

ensure-env:
	@test -f .env || { \
	  echo "Missing testing/sandbox/.env. Create it:"; \
	  echo "    cp .env.example .env   # then paste your CLAUDE_CODE_OAUTH_TOKEN"; \
	  exit 1; }

build: ensure-env
	$(COMPOSE) build runner

# Which cluster you hit is decided by the TARGET, never your shell. Local targets
# fix the cluster to the bundled container (the entrypoint overrides any CB_*);
# remote targets read CB_* from .env. HARNESS_MODE / CB_PROFILE are injected per-run
# via `run -e` so a stray exported var can't change the run.
sandbox: ensure-env
	$(COMPOSE) --profile local run --rm \
	  -e HARNESS_MODE=sandbox -e CB_PROFILE=local \
	  runner

sandbox-remote: ensure-env
	$(COMPOSE) run --rm \
	  -e HARNESS_MODE=sandbox -e CB_PROFILE=remote \
	  runner

# Setup-flow targets: identical to the sandbox targets except HARNESS_PREWIRE_MCP=0,
# so the REPL starts with NO MCP server connected — the state couchbase-mcp-setup
# expects to drive itself. Local target still provisions the bundled cluster (so the
# skill has a real backend at couchbase://couchbase); remote target leaves the
# connection to the skill (set CB_* in .env to verify against real Capella, or leave
# them blank to exercise the cold "gather details" path).
sandbox-setup: ensure-env
	$(COMPOSE) --profile local run --rm \
	  -e HARNESS_MODE=sandbox -e CB_PROFILE=local -e HARNESS_PREWIRE_MCP=0 \
	  runner

sandbox-setup-remote: ensure-env
	$(COMPOSE) run --rm \
	  -e HARNESS_MODE=sandbox -e CB_PROFILE=remote -e HARNESS_PREWIRE_MCP=0 \
	  runner

# True first-time setup: provisions the bundled local cluster, then strips ALL CB_*
# from the session env (HARNESS_SEED_CB_ENV=0) before launching the REPL — so the
# agent sees no connection string, creds, or MCP server at all and must drive the
# whole couchbase-mcp-setup flow from scratch. (Cold Capella: use sandbox-setup-remote
# with a blank .env.)
sandbox-setup-cold: ensure-env
	$(COMPOSE) --profile local run --rm \
	  -e HARNESS_MODE=sandbox -e CB_PROFILE=local \
	  -e HARNESS_PREWIRE_MCP=0 -e HARNESS_SEED_CB_ENV=0 \
	  runner

clean:
	-$(COMPOSE) --profile local down -v --remove-orphans
