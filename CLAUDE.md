# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Docker image for Railway that provides a full Ubuntu development environment accessible via SSH. Deploys on Railway with a TCP proxy for SSH access.

## Build & Test

```bash
# Build the Docker image
docker build -t railway-ubuntu-sshd .

# Run locally (requires SSH_USERNAME and SSH_PASSWORD)
docker run -p 2222:22 -e SSH_USERNAME=user -e SSH_PASSWORD=pass railway-ubuntu-sshd

# Test SSH connection locally
ssh -p 2222 user@localhost
```

There are no automated tests or linting — validation is done by building the image and connecting via SSH.

## Architecture

**Runtime flow:** `entrypoint.sh` → validates env vars → creates user → configures SSH → starts `supervisord` (manages `sshd` + `cron`)

**Key files:**
- `Dockerfile` — Multi-stage install: system packages, Node.js LTS, pnpm, Claude Code CLI, GitHub CLI, Rust/Cargo, Homebrew
- `scripts/entrypoint.sh` — Container init: user creation, SSH key setup, npm config, host key generation, supervisord launch
- `config/sshd_config` — SSH server config (root login disabled, X11 forwarding enabled, keepalive settings)
- `config/supervisord.conf` — Process manager for sshd and cron daemons
- `railway.toml` — Railway platform config (dockerfile builder)

**Environment variables (set at runtime):**
- `SSH_USERNAME` / `SSH_PASSWORD` — required, user creation credentials
- `ROOT_PASSWORD` — optional root password
- `AUTHORIZED_KEYS` — optional; when set, password auth is automatically disabled

**Persistent storage:** User home directories live under `/data/$SSH_USERNAME` (volume mount). Container filesystem is ephemeral — anything outside `/data` is lost on redeploy.

**Homebrew:** Installed under a dedicated `linuxbrew` user, made accessible to all users via `/etc/profile.d/homebrew.sh`. The `linuxbrew` user is not for SSH access.
