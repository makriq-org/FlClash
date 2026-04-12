<div>

[**简体中文**](README_zh_CN.md)

</div>

# FlClash Hardened

[![Downloads](https://img.shields.io/github/downloads/makriq3/FlClash/total?style=flat-square&logo=github)](https://github.com/makriq3/FlClash/releases/)[![Last Version](https://img.shields.io/github/release/makriq3/FlClash/all.svg?style=flat-square)](https://github.com/makriq3/FlClash/releases/)[![License](https://img.shields.io/github/license/makriq3/FlClash?style=flat-square)](LICENSE)

Privacy-hardened FlClash fork with a strong focus on Android VPN safety, localhost leak reduction, and release automation that is independent from upstream infrastructure.

## What Makes This Fork Different

- Android VPN mode is hardened against localhost proxy leaks.
- Android VPN hardening is enforced at runtime, including live config refreshes after startup.
- Android release verification is designed around GitHub Actions, not repeated manual APK installs.
- Research and mitigation notes live in the repository itself.

## Current Priorities

1. Reduce app-visible Android leak surface without requiring root.
2. Keep the repository self-contained and releasable from this fork.
3. Build a stable base for future privacy and usability features.

## Research And Security Docs

- [Android VPN Hardening Research](docs/android-vpn-hardening.md)
- [Security Policy](SECURITY.md)
- [Roadmap](ROADMAP.md)
- [ChangeLog](CHANGELOG.md)

## Screenshots

Desktop:
<p style="text-align: center;">
    <img alt="desktop" src="snapshots/desktop.gif">
</p>

Mobile:
<p style="text-align: center;">
    <img alt="mobile" src="snapshots/mobile.gif">
</p>

## Highlights

- Multi-platform: Android, Windows, macOS, Linux
- Flutter UI with Clash-compatible workflow
- WebDAV sync support
- Subscription support
- Android VPN hardening for privacy-sensitive deployments

## Android Hardening Snapshot

In Android VPN mode this fork now closes client-side leak paths such as:

- localhost mixed / socks / http listeners,
- localhost-accessible external controller,
- Android system proxy exposure,
- stable tunnel fingerprint values.

The current hardening model also restores correct domain-based routing on the hardened TUN path, so Android direct-route rules keep working without reopening the original localhost leak surface.

Important: this fork reduces what the client leaks by itself. It does not claim to fully hide VPN presence from Android public APIs without root/Xposed.

## Build

1. Update submodules

   ```bash
   git submodule update --init --recursive
   ```

2. Install Flutter and Go

3. Install Android SDK and Android NDK for Android builds

4. Build:

   ```bash
   dart setup.dart android
   dart setup.dart windows --arch amd64
   dart setup.dart linux --arch amd64
   dart setup.dart macos --arch arm64
   ```

## Releases

- Branch Android artifacts: GitHub Actions `android-branch-build`
- Stable multi-platform release: tag push `v*`

## Project Direction

This repository is being developed as a maintained privacy-hardened fork, not just a mirror of upstream releases.

That means this fork will gradually build its own:

- Android privacy hardening policy,
- release pipeline,
- security documentation,
- and feature roadmap.

## Upstream

This repository started as a fork of [chen08209/FlClash](https://github.com/chen08209/FlClash). Upstream deserves full credit for the original project and cross-platform base.
