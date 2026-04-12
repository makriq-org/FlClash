# Roadmap

## Direction

This fork is focused on turning FlClash into a more privacy-conscious and operationally independent Android-first VPN client.

The near-term goal is not to promise impossible "zero detection" claims. The goal is to remove avoidable client-side leaks, ship safer defaults, and make releases reproducible from this repository alone.

## Current Track

### 1. Android Privacy Hardening

- Keep localhost listener exposure closed in Android VPN mode.
- Reduce fingerprintable static values where it can be done safely.
- Add regression coverage for privacy-sensitive config generation paths.

### 2. Release Independence

- Build Android and stable releases from this fork's GitHub Actions.
- Keep release metadata, templates, and documentation maintained locally.
- Reduce assumptions about upstream-only infrastructure.

### 3. Product Foundation

- Keep the repository ready for future privacy and UX features.
- Document threat model and mitigation boundaries inside the repository.
- Prefer "safe by default" behavior for Android-focused deployments.

## Non-Goals

- Claiming that a client-only app can fully hide VPN usage from Android public APIs without root.
- Replacing device-side root/Xposed masking for users who need stronger anti-detection guarantees.
