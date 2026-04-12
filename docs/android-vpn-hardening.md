# Android VPN Hardening Research

## Why This Document Exists

This fork exists because Android VPN clients can leak practical indicators to other apps even when traffic is routed through `VpnService`.

The most dangerous client-side issue is not simply that Android knows a VPN exists. The more serious problem is when the client exposes extra localhost listeners or system proxy settings that let another app:

- detect the client family,
- connect to a local proxy,
- and recover the VPN exit IP or other metadata.

## Threat Model

We focus on what a regular Android app can see without root:

- `NetworkCapabilities.TRANSPORT_VPN`
- `NET_CAPABILITY_NOT_VPN`
- loopback ports on `127.0.0.1` / `::1`
- `System.getProperty("http.proxyHost")`
- `System.getProperty("socksProxyHost")`
- `LinkProperties.dnsServers`
- `NetworkInterface` enumeration
- `/proc/net/tcp*`, `/proc/net/udp*`, `/proc/net/route`

We do not treat privileged root/Xposed API hiding as a client-only solution. That is a separate device-side layer.

## Findings Relevant To FlClash

Before hardening, FlClash on Android had several practical indicators:

- a local mixed proxy could remain available on localhost,
- Android `systemProxy` support could publish `127.0.0.1:<port>` to the system,
- `allowBypass` could permit bypass behavior that weakens privacy guarantees,
- `VpnService` used stable, fingerprintable tunnel addresses and a stable session name.

These indicators make app-side detection easier and can turn a VPN client into an IP leak source for the entire server.

## What This Fork Changes

In Android VPN mode this fork now:

- forces all localhost inbound listeners closed in generated Clash config:
  - `port=0`
  - `socks-port=0`
  - `mixed-port=0`
  - `redir-port=0`
  - `tproxy-port=0`
- forces `external-controller=''`
- forces `allow-lan=false`
- forces `systemProxy=false`
- forces `allowBypass=false`
- stops routing app-owned HTTP requests through the localhost mixed proxy while Android VPN mode is active
- randomizes per-start IPv4 / IPv6 tunnel addresses
- uses a neutral `VpnService` session name (`VPN`)

## What This Fork Does Not Claim To Solve

This fork does **not** claim to eliminate all Android VPN detection.

Without root/Xposed/LSPosed-style API masking, a normal Android app can still observe:

- `TRANSPORT_VPN`
- the missing `NET_CAPABILITY_NOT_VPN`
- some TUN / route / DNS / MTU level signals

This means:

- client hardening can remove practical localhost leaks and reduce fingerprinting,
- but full "no VPN signs at all" is not realistic from the client alone.

## Release And Verification Policy

For Android privacy fixes, we want one release to validate several things at once.

Every release should check:

1. localhost listener surface is closed in Android VPN mode,
2. no unexpected `external-controller` exposure exists,
3. app-owned requests do not depend on localhost mixed proxy while VPN mode is active,
4. detector apps such as `YourVPNDead` do not recover exit IP through localhost.

## Notes On Public Claims

We treat some public claims around Android VPN detection as partially verified and partially speculative.

- App-side localhost and Android API based detection is real and reproducible.
- Exact public claims about enforcement timelines or unpublished official methodologies should be treated carefully unless independently confirmed.
