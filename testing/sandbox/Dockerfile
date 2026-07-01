# Fresh, reproducible environment for testing the Couchbase agent skills with the
# real Claude Code CLI. Contains: Claude Code, uv/uvx (to run the Couchbase MCP
# server) and the usual CLI plumbing. The repo working tree is bind-mounted at
# /work at runtime — it is NOT baked in — so local skill edits are picked up
# without a rebuild.
FROM node:22-bookworm-slim

ARG CLAUDE_CODE_VERSION=latest
ARG MCP_SERVER_SPEC="couchbase-mcp-server>=1.0.0,<1.1.0"
ARG SKILL_INSTALL_MODE=local
ARG SKILLS_MARKETPLACE="Couchbase-Ecosystem/agent-skills"

# The container runs as the non-root `node` user (Claude Code refuses
# --dangerously-skip-permissions as root). Claude Code + its native binary are
# installed AS node into a node-owned npm prefix, with HOME set, so the binary
# and config dir are consistent between build and runtime.
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    HOME=/home/node \
    CLAUDE_CONFIG_DIR=/home/node/.claude \
    UV_CACHE_DIR=/opt/uv-cache \
    NPM_CONFIG_PREFIX=/home/node/.npm-global \
    PATH="/home/node/.npm-global/bin:/usr/local/bin:${PATH}"

# Runtime tooling. python3 runs the smoke-test runner (run-tests.py); couchbase-cli
# is intentionally NOT installed — cluster init uses the plain REST API via curl,
# which keeps the image small.
RUN apt-get update && apt-get install -y --no-install-recommends \
        jq git curl ca-certificates python3 \
    && rm -rf /var/lib/apt/lists/*

# uv / uvx → installed to a global path so the non-root user can run them.
RUN curl -LsSf https://astral.sh/uv/install.sh \
      | env UV_INSTALL_DIR=/usr/local/bin INSTALLER_NO_MODIFY_PATH=1 sh \
    && mkdir -p /opt/uv-cache \
    && uvx --version

# Pre-warm the MCP server into the shared uv cache so the sandbox doesn't need
# PyPI at runtime (best-effort).
RUN uvx --from "${MCP_SERVER_SPEC}" couchbase-mcp-server --help >/dev/null 2>&1 || true

# Harness assets (the only things copied into the image). Hand the npm prefix +
# uv cache to node.
COPY scripts/ /opt/harness/scripts/
COPY entrypoint.sh run-tests.py /opt/harness/
RUN chmod +x /opt/harness/entrypoint.sh /opt/harness/scripts/*.sh /opt/harness/run-tests.py \
    && mkdir -p /home/node/.npm-global \
    && chown -R node:node /home/node /opt/uv-cache

ENV SKILL_INSTALL_MODE=${SKILL_INSTALL_MODE} \
    SKILLS_MARKETPLACE=${SKILLS_MARKETPLACE}

# Everything below runs as the non-root user.
USER node
# Install Claude Code as node (pin via --build-arg HARNESS_CLAUDE_CODE_VERSION),
# and verify the non-root user can actually run it.
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} \
    && claude --version

WORKDIR /work
ENTRYPOINT ["/opt/harness/entrypoint.sh"]
