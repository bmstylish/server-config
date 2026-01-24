# Architecture

Personal Ubuntu Server (mini-PC) running behind CGNAT. Primary goals: secure remote access, reliable monitoring, and reproducible configuration via Git.

---

## 1) System overview

### Host
- **OS:** Ubuntu Server
- **Hardware:** mini-PC
- **Network:** behind **CGNAT** (no inbound port forwarding)

### Access model
- **Primary remote access:** SSH over **Tailscale**
- **Public exposure:** none by default (future option: Cloudflare Tunnel / reverse proxy)

### Design principles
- **Least privilege:** services run as dedicated users where appropriate
- **Secrets never in Git:** configuration repo contains examples only
- **Reproducibility:** server state is described by documented configs + unit files
- **Fail loud:** monitoring posts notifications on boot and on schedules

---

## 2) Components

### 2.1 Monitoring scripts (local)

Location (live):
- local user scripts directory (not tracked in Git)

Responsibilities:
- Collect basic health signals (uptime, load, disk, temperature, etc.)
- Send formatted notifications to Discord via webhook

---

### 2.2 Secrets management

- **Primary secret:** Discord webhook URL
- **Canonical secret file (root-owned):** `/etc/server-secrets.env`
- **Optional user copy (dev/testing):** user-scoped environment file

Rules:
- No secrets committed to Git
- systemd services load secrets via an `EnvironmentFile`
- Scripts reference environment variables only (no hardcoded values)

---

### 2.3 systemd units

Services:
- `boot-alert.service`  
  Sends a notification when the machine boots
- `status-report.service`  
  Sends periodic health/status reports
- `status-report.timer`  
  Triggers reports on a schedule

Reliability considerations:
- Ensure network/time readiness before outbound HTTPS calls
- Services fail safely and log clearly via journal

---

### 2.4 Discord server-management bot

Stack:
- Python 3.12+
- `discord.py 2.x` (slash commands)
- Stateless / no database

Runtime:
- Runs under a **dedicated service account**
- Managed by a systemd unit
- Provides read-only operational visibility (examples):
  - `/status` (service status, host signals)
  - `/logs` (limited recent logs)

Security notes:
- Permissions intentionally minimal
- Least-privilege access to system information only

---

## 3) Repository layout (source-of-truth vs live)

This project follows a “config repo” pattern: Git contains templates and references, not live secrets or volatile files.

Repo (example): `server-config`

Contains:
- systemd unit files
- timers
- example scripts/templates
- reference configs (netplan, sshd, ufw)
- documentation

Does **not** contain:
- secret files
- real webhook URLs
- private keys
- tokens
- machine-specific identifiers
- runtime logs

---

## 4) Data flows

### 4.1 Boot notification
1. systemd starts boot alert service
2. service loads secrets from root-owned environment file
3. script posts a message to Discord

### 4.2 Scheduled status report
1. timer fires
2. report service runs
3. loads secrets
4. collects host signals and posts to Discord

### 4.3 Bot slash command (read-only)
1. user invokes command in Discord
2. bot performs local read-only checks
3. bot responds with status information

---

## 5) Security posture

### Network
- No inbound exposure due to CGNAT (by design)
- Remote administration via Tailscale + SSH hardening

### Secrets
- Stored outside Git in a root-owned environment file
- Minimal distribution to services only

### Principle of least privilege
- Dedicated service accounts
- Minimal permissions
- systemd sandboxing where applicable

---

## 6) Operational runbook (quick commands)

Status:
- `systemctl status boot-alert.service`
- `systemctl status status-report.service`
- `systemctl list-timers | grep status-report`
- `journalctl -u boot-alert.service -b`
- `journalctl -u status-report.service -n 200 --no-pager`

Secrets:
- `sudo cat /etc/server-secrets.env` (verify exists and is root-owned)
- `systemctl show -p Environment <unit>` (confirm env is loaded)

---

## 7) Backlog (next hardening steps)

### systemd sandboxing (recommended)
Add to services where applicable:
- `NoNewPrivileges=yes`
- `ProtectSystem=strict`
- `ProtectHome=yes`
- `PrivateTmp=yes`
- `ProtectKernelTunables=yes`
- `ProtectKernelModules=yes`
- `ProtectControlGroups=yes`
- `LockPersonality=yes`
- `RestrictSUIDSGID=yes`
- `RestrictNamespaces=yes`
- `SystemCallFilter=@system-service`

### Public access (optional)
If a public endpoint is needed behind CGNAT:
- Cloudflare Tunnel to a single reverse proxy/service
- strict authentication + logging

### Monitoring depth
- Add metrics + dashboards or lightweight logging + alerts
- Add automated backups + periodic restore tests
