# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **GitBook-based documentation site** — a Cardano Stake Pool installation guide targeting Linux operators. There is no application code, build system, or test suite. The deliverable is markdown content rendered by GitBook.

The guide covers the full SPO lifecycle: server setup, node installation (currently cardano-node 10.6.2), relay/block-producer configuration, key generation, pool registration, and upgrades.

## Content Structure

- **SUMMARY.md** — GitBook table of contents and navigation tree. Every new or renamed page must be reflected here.
- **README.md** — Landing page (hardware requirements, prerequisites overview).
- Top-level `.md` files — Early setup steps (user creation, swap, prerequisites, node install).
- **cardano-relay-configuration/** — Relay node config, blockchain sync, launching relays.
- **cardano-block-producer-configuration/** — SPOS scripts, wallet keys, BP keys, launching BP.
- **cardano-node-upgrades/** — Version-specific upgrade guides.
- **legacy/** — Archived guides for older node versions (kept for reference, not actively maintained).
- **.gitbook/assets/** — Images and embedded scripts referenced from content pages.

## Authoring Conventions

**Front matter**: Every markdown file starts with YAML front matter containing a `description` field:
```yaml
---
description: Brief description of the page
---
```

**GitBook syntax** used throughout:
- Hints: `{% hint style="success" %}`, `{% hint style="info" %}`, `{% hint style="warning" %}`
- Tabs: `{% tabs %}` / `{% tab title="..." %}` / `{% endtab %}` / `{% endtabs %}`
- Image refs: `![alt text](<.gitbook/assets/filename>)` (angle brackets around path)

**Canonical paths**: The guide standardizes on `/home/cardano/cnode/` with subdirectories `config`, `db`, `sockets`, `keys`, `logs`, `scripts`. All examples use the `cardano` system user. Do not change these paths without considering backward compatibility for existing SPOs.

**Network variants**: When commands differ between Mainnet and Testnet (pre-prod), provide both using GitBook tabs. The default/primary path is always Mainnet.

## Key Editing Guidelines

- Keep commands copy-paste-ready — operators run these on production servers.
- When updating for a new cardano-node version: update README.md version reference, create a new upgrade guide in `cardano-node-upgrades/`, update SUMMARY.md, and review all pages that reference version-specific downloads or config files.
- Preserve legacy/archive sections rather than deleting old version content.
- Asset filenames with spaces are common (historical CleanShot screenshots) — always use angle-bracket syntax for paths in image references.
