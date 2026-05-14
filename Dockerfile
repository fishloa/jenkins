FROM jenkins/jenkins:lts

USER root

# System packages used by the zenith Jenkinsfile:
#  - python3 + pip     → scripts/test_find_redundant.py, scripts/coverage-diff.py
#  - jq                → handy in pipeline `sh` steps for parsing JSON
#  - unzip             → bun installer extracts a zip
#  - ca-certificates,  → already in jenkins/jenkins:lts but pinned explicitly
#    curl, git, make
#
# Docker CLI is NOT installed here — the docker-compose mounts the host
# binary read-only at /usr/bin/docker (and cli-plugins).
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        jq \
        unzip \
        make \
 && rm -rf /var/lib/apt/lists/*

# bun + bunx — used by `bun install`, `bun run lint:fetch`, `bunx <tool>`,
# and `make contracts-check`. Install to /usr/local/bin so both names are
# on PATH for every user/agent without touching home dirs.
ARG BUN_VERSION=latest
RUN curl -fsSL https://bun.sh/install | bash -s "${BUN_VERSION}" \
 && mv /root/.bun/bin/bun /usr/local/bin/bun \
 && ln -sf /usr/local/bin/bun /usr/local/bin/bunx \
 && chmod 0755 /usr/local/bin/bun \
 && rm -rf /root/.bun

USER jenkins
