# Security Policy

## Scope

This fork prioritizes Android VPN privacy hardening, especially around:

- localhost proxy exposure,
- app-visible VPN indicators that can be reduced client-side,
- safer defaults for Android `VpnService` mode.

## What To Report

Please open a security issue if you find:

- a localhost listener exposed in Android VPN mode,
- an unauthenticated API or proxy reachable by another app on the same device,
- a configuration path that silently re-enables risky Android defaults,
- a release workflow regression that publishes artifacts from the wrong repository context.

## What Is Out Of Scope For Client-Only Fixes

This fork cannot fully hide Android VPN presence from public Android APIs without device-side root hooking.

Examples:

- `NetworkCapabilities.TRANSPORT_VPN`
- `NET_CAPABILITY_NOT_VPN`
- some route / interface / DNS signals visible to apps

For background and current mitigation strategy, see [docs/android-vpn-hardening.md](docs/android-vpn-hardening.md).
