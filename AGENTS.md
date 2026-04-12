# AGENTS.md

## Client (FlClash)

### Working Context

- Repository fork created under `makriq3/FlClash`.
- Local repo path: `/home/max/Projects/Prod/FlClash`.
- Current upstream HEAD at inspection time: commit `672eacc` (`Update changelog`).
- Git remotes:
  - `origin` -> `https://github.com/makriq3/FlClash.git`
  - `upstream` -> `https://github.com/chen08209/FlClash.git`

### App Architecture

- FlClash is a Flutter app with Android-specific `VpnService` code and a Go core based on `mihomo` + `sing-tun`.
- Main Android VPN entrypoint:
  - `android/service/src/main/java/com/follow/clash/service/VpnService.kt`
- TUN startup path:
  - Android `VpnService` builds the tunnel and passes the FD into Go via `Core.startTun(...)`.
  - Go TUN implementation lives in:
    - `core/tun/tun.go`
    - `core/lib.go`
- Network observation / DNS refresh lives in:
  - `android/service/src/main/java/com/follow/clash/service/modules/NetworkObserveModule.kt`

### Relevant Current Defaults

- `mixed-port` default is `7890`:
  - `lib/models/clash_config.dart`
- `socks-port` default is `0`, but the active Android `VpnOptions.port` is derived from `mixed-port`:
  - `lib/providers/state.dart`
- `VpnProps.systemProxy` default is `true`:
  - `lib/models/config.dart`
- `VpnProps.allowBypass` default is `true`:
  - `lib/models/config.dart`
- `VpnProps.dnsHijacking` default is `false`:
  - `lib/models/config.dart`
- `external-controller` default is closed (`''`), and explicit open state is `127.0.0.1:9090`:
  - `lib/enum/enum.dart`
  - `lib/models/clash_config.dart`

### Confirmed Detection / Leak Surface In Current Code

- Android `VpnService` is always used when VPN mode is enabled:
  - `android/service/.../VpnService.kt`
- `VpnService` currently exposes stable, fingerprintable values:
  - session name: `FlClash`
  - IPv4 tunnel address: `172.19.0.1/30`
  - IPv4 DNS advertised to system: `172.19.0.2`
  - IPv6 tunnel address: `fdfe:dcba:9876::1/126`
  - IPv6 DNS advertised to system: `fdfe:dcba:9876::2`
- On Android 10+ (`API 29+`) FlClash can publish a system HTTP proxy pointing to `127.0.0.1:<mixed-port>` when `systemProxy=true`:
  - `android/service/.../VpnService.kt`
- The Go core recreates inbound listeners for HTTP / SOCKS / mixed / redir / tproxy according to config:
  - `core/common.go`
- Because `mixed-port` defaults to `7890`, current Android flow effectively keeps a localhost mixed proxy available unless user changes config.
- `mixed-port` in mihomo supports both HTTP and SOCKS5 on one port. This means a localhost leak is still possible even with `socks-port=0`.
- FlClash itself globally routes many app HTTP requests through the local mixed proxy via `HttpOverrides`:
  - `lib/main.dart`
  - `lib/common/http.dart`
  - `lib/common/request.dart`
- Consequence:
  - enabling proxy auth on localhost is not a drop-in fix by itself;
  - the app must either learn to authenticate to its own local proxy, or Android TUN mode must stop depending on that local mixed proxy path.

### External Evidence Collected

- Upstream FlClash issue `#1934` opened on `2026-04-08`:
  - title: `[SECURITY] Critical vulnerability: SOCKS5 localhost proxy bypass allows discovery of outbound IP`
  - repo: `chen08209/FlClash`
- The issue discussion points to a practical mitigation direction:
  - secure-by-default auth for local proxy, or
  - disabling local SOCKS/mixed inbound when TUN mode is active.
- Official mihomo docs confirm:
  - `mixed-port` supports both HTTP and SOCKS.
  - global `authentication:` can protect `http`, `socks`, and `mixed` proxies.
  - `skip-auth-prefixes` can exclude ranges like `127.0.0.1/8`, so it must be handled carefully for localhost hardening.

### Research On Detection Tools

- `NoVPNDetect` is an Xposed module. It does not fix the VPN client itself; it hooks Android APIs seen by other apps.
- In inspected code, `NoVPNDetect` hooks and falsifies:
  - `NetworkCapabilities.hasTransport(TRANSPORT_VPN)`
  - `NetworkCapabilities.hasCapability(NET_CAPABILITY_NOT_VPN)`
  - `NetworkCapabilities.getCapabilities()`
  - `NetworkInterface.getName()`
  - `NetworkInterface.getByName()`
  - `NetworkInterface.isUp()`
  - `NetworkInterface.isVirtual()`
- Practical meaning:
  - Some app-visible VPN signs cannot be removed by FlClash alone.
  - Those signs require root/Xposed/LSPosed-style API hiding on the device.

- `YourVPNDead` is a detector app focused on practical app-visible leak paths.
- Inspected checks include:
  - `NetworkCapabilities.TRANSPORT_VPN`
  - `NetworkCapabilities.NET_CAPABILITY_NOT_VPN`
  - `System.getProperty("http.proxyHost" / "socksProxyHost")`
  - `NetworkInterface` enumeration for `tun*`, `wg*`, `ppp*`, etc.
  - `/proc/net/route`
  - `ConnectivityManager.getLinkProperties(...).dnsServers`
  - localhost port scans on `127.0.0.1` and `::1`
  - `/proc/net/tcp*` and `/proc/net/udp*`
  - SOCKS5 handshake probing
  - Clash API probing on `9090` / `19090`
  - exit IP extraction through unauthenticated localhost proxy

### What FlClash Can Realistically Fix By Itself

- Close or harden localhost inbound proxy exposure in Android VPN mode.
- Make safer defaults so users are not vulnerable out of the box.
- Potentially reduce obvious fingerprinting from static session / address / DNS values where platform constraints allow it.
- Add a dedicated hardened / stealth mode so subscription updates do not silently undo safety-critical local settings.
- Improve verification workflow so one build can validate several hypotheses at once.

### What FlClash Cannot Fully Fix By Itself

- Android reporting VPN transport via `NetworkCapabilities`.
- Absence of `NET_CAPABILITY_NOT_VPN` on the active VPN network.
- Visibility of TUN-style interfaces and some route / MTU / DNS signs to apps using public Android APIs.
- These require device-side root hooking / API hiding tools such as Xposed/LSPosed modules.

### Initial Priority Assessment

1. Highest priority:
   - localhost mixed/http/socks exposure and any auth-less inbound reachable by other apps.
2. High priority:
   - system proxy visibility (`127.0.0.1:<port>`) when not strictly required.
3. Medium priority:
   - stable static identifiers (`FlClash`, tunnel addresses, tunnel DNS) that can aid heuristics.
4. Out of scope for client-only fix:
   - direct Android VPN API detection without root hooks.

### Build / CI Notes

- Existing GitHub Actions workflow in this repo builds Android artifacts, but currently triggers on tag push (`v*`) rather than branch push / manual testing flow.
- For fast iteration in fork `makriq3/FlClash`, a dedicated Android test/build workflow will likely be needed so heavy builds happen in GitHub Actions without local machine load.
- Because the risk here is mostly runtime behavior, validation should combine:
  - code-level assertions for generated config / safe defaults,
  - CI-built APK artifacts,
  - one batched manual device run against detector apps instead of repeated per-edit installs.

### Validation Direction

- Avoid repeated manual APK installs by batching fixes and validating them against a fixed checklist:
  - no localhost leak through mixed / socks / http
  - no unexpected external controller exposure
  - expected behavior in TUN mode
  - explicit comparison against detector apps (`YourVPNDead`, `NoVPNDetect` where applicable)
- Important constraint:
  - a "clean" result in detector apps is only partially achievable by client changes alone;
  - full "no detect" for Android usually requires FlClash hardening plus root/Xposed masking.

### Implemented Hardening In This Fork

- Added Android-only runtime hardening for VPN mode:
  - force-close localhost listeners in generated Clash config:
    - `port=0`
    - `socks-port=0`
    - `mixed-port=0`
    - `redir-port=0`
    - `tproxy-port=0`
  - force `external-controller=''`
  - force `allow-lan=false`
- Added Android-only VPN option hardening:
  - force `systemProxy=false`
  - force `allowBypass=false`
  - clear `bypassDomain`
  - force local proxy port in `VpnOptions` to `0`
- Added Android request-path hardening:
  - app-owned HTTP traffic no longer routes through localhost mixed proxy while Android VPN mode is active.
  - this prevents the app from depending on the same localhost listener surface we are trying to close.
- Added Android-side fingerprint reduction in `VpnService`:
  - randomized per-start IPv4/IPv6 tunnel addressing instead of static `172.19.0.1/30` and `fdfe:dcba:9876::/126`
  - generic session name `VPN` instead of `FlClash`
- Added regression coverage:
  - `test/common/android_vpn_hardening_test.dart`
- Added branch/manual Android GitHub Actions workflow for the fork:
  - `.github/workflows/android-branch-build.yml`

### Android Routing Regression Investigation (2026-04-12)

- Upstream security issue confirmed:
  - `chen08209/FlClash` issue `#1934`
  - title: `[SECURITY] Critical vulnerability: SOCKS5 localhost proxy bypass allows discovery of outbound IP`
  - opened on `2026-04-07`
- The Android hardening release in this fork is commit:
  - `b8abc74` (`Prepare hardened fork release v0.8.93`)
- Security hardening did change:
  - generated Clash patch config for Android VPN mode
  - app-local HTTP proxy usage
  - Android `VpnService` tunnel identity values
- Security hardening did **not** change:
  - Android `protect()` bridge wiring into Go core
  - Go TUN startup hook that applies socket protection for direct outbound connections
  - rule list generation in `makeRealProfileTask(...)`

### Confirmed Route Handling Split

- There are two separate routing layers in the Android flow:
  - generated Clash core config (`tun.route-address`, rules, DNS, etc.)
  - Android `VpnService.Builder.addRoute(...)` decisions from `VpnOptions.routeAddress`
- The generated Clash config still preserves the resolved TUN route list:
  - `lib/controller.dart` computes `patchConfig.tun.getRealTun(routeMode)`
  - `lib/common/task.dart` writes it into raw config as `rawConfig['tun']['route-address']`
- `Tun.getRealTun(RouteMode routeMode)` resolves:
  - `RouteMode.config` -> user config `tun.route-address`
  - `RouteMode.bypassPrivate` -> `defaultBypassPrivateRouteAddress`
  - if the final list is empty on mobile, `auto-route=true`; otherwise `auto-route=false`

### Confirmed Android Service Gap

- `VpnOptions` includes `routeAddress` on both Flutter and Android sides:
  - Flutter: `lib/models/core.dart`
  - Android parcelable: `android/service/.../VpnOptions.kt`
- Android `VpnService` explicitly relies on `options.routeAddress`:
  - if non-empty, it adds only those routes
  - if empty, it falls back to `addRoute(0.0.0.0, 0)` and `addRoute(::, 0)`
- Current `SharedState` construction does **not** populate `VpnOptions.routeAddress`:
  - `lib/providers/state.dart` builds `VpnOptions(...)` without `routeAddress`
- Practical consequence:
  - Android service receives an empty route list even when final Clash config contains a non-empty `tun.route-address`
  - system VPN routing and core TUN config can therefore diverge

### Historical Note

- This `routeAddress` omission predates the hardening commit:
  - `b8abc74` kept building `VpnOptions` without `routeAddress`
  - so the bug may be older than the security fix and only became visible after hardening changed the traffic path / test conditions

### Current Working Hypothesis

- Strong hypothesis:
  - Android-side routing regression is caused by `VpnOptions.routeAddress` not being synchronized with the resolved `tun.route-address`
  - because of that, `VpnService` installs full-capture routes even when config expects a narrower route set
- Still not fully proven:
  - whether the user-visible `RU via VPN` symptom comes entirely from this route divergence
  - or whether there is a second issue in direct-outbound handling for Clash `DIRECT` rules
- Important distinction:
  - the generated Clash config itself still appears to preserve rules and `tun.route-address`
  - the strongest confirmed mismatch is between generated core config and Android `VpnService` route installation

### Refined Regression Hypothesis After User Reproduction Note

- User-reported behavior:
  - with the same practical config, `2ip.ru` went direct before the fork
  - after the fork / hardening release, `2ip.ru` goes through VPN
- This makes a pure "old hidden bug" explanation less likely as the primary cause.
- Stronger fork-specific regression candidate:
  - before the fork, Android path preserved `systemProxy=true` and non-empty `bypassDomain`
  - after the fork, Android defaults and runtime hardening now force:
    - `systemProxy=false`
    - `allowBypass=false`
    - `bypassDomain=[]`
    - `port=0`
- Evidence:
  - upstream/default Android settings previously inherited normal defaults
  - fork now overrides Android defaults in `lib/providers/config.dart`
  - fork also force-overrides active `VpnOptions` in `lib/common/android_vpn_hardening.dart`
  - Android `VpnService` uses `bypassDomain` only when `systemProxy=true` through `ProxyInfo.buildDirectProxy(...)`
- Practical meaning:
  - if the observed "RU direct" behavior depended on Android system proxy bypass domains rather than Clash rule evaluation inside TUN, the fork would break it immediately even with the same visible profile config
- Current best explanation ranking:
  1. most likely:
     - fork hardening removed Android `systemProxy` + localhost mixed-proxy path that previously let browser/app traffic reach Clash as proxy traffic instead of only raw TUN traffic
     - if user routing relied on Android proxy bypass domains or on domain-based Clash rules that worked better on the proxy path, this would immediately regress after hardening
  2. still possible / secondary:
     - missing `VpnOptions.routeAddress` causes route divergence between Android `VpnService` and generated Clash config
  3. less likely but not excluded:
     - an additional regression in direct-outbound handling for Clash `DIRECT` rules inside Android TUN

### Reproduced Mechanism

- The core routing failure is now reproduced at rule-matching level against local `mihomo` packages in a temporary Go module:
  - a `DOMAIN-SUFFIX,ru,DIRECT` rule matches `Metadata{Host: "2ip.ru"}`
  - the same rule does **not** match IP-only metadata (`Metadata{DstIP: ...}`)
- This confirms the practical regression mechanism:
  - before hardening, Android browser/app traffic could arrive through the localhost proxy path with domain metadata preserved
  - after hardening, traffic is forced onto raw TUN and can become IP-only unless domain recovery is explicitly enabled
  - in that state, domain-based rules such as `DOMAIN*`, `GEOSITE`, and many rule-set based direct routes can silently stop matching
- Conclusion:
  - `routeAddress` was a real bug and still needed fixing
  - but the user-visible `2ip.ru -> VPN` regression is better explained by loss of domain-aware matching after hardening removed the proxy path

### Implemented Follow-Up Fixes (Pending CI Verification)

- Kept Android-safe TUN route synchronization:
  - `SharedState.vpnOptions.routeAddress` is derived from the same resolved TUN config logic as profile generation
  - this still closes the confirmed route mismatch between Flutter-side config generation and Android `VpnService`
- Refined the Android routing fix after failed manual validation:
  - removed fork-specific Android default overrides from `VpnSetting`, `NetworkSetting`, and `PatchClashConfig`
  - hardening remains runtime-only in active Android VPN mode instead of rewriting the app's baseline defaults
- Strengthened Android VPN profile compatibility so it no longer depends on `requestedSystemProxy=true`:
  - whenever hardened Android VPN mode is active, profile generation now:
    - translates compatible `bypassDomain` entries into top-priority `DIRECT` Clash rules
    - always enables / augments `sniffer` for `http`, `tls`, and `quic`
- Rationale:
  - the previous compatibility attempt could stay inert if forked Android defaults had already forced `systemProxy=false`
  - always-on domain recovery is safer for the hardened TUN-only path and directly targets the reproduced loss of host metadata

### Follow-Up Security Regression Found After Device Validation

- After restoring normal Android defaults, a localhost exposure regression reappeared.
- Root cause:
  - profile generation was still hardened correctly during setup
  - but runtime live updates use `updateParamsProvider -> coreController.updateConfig(...)`
  - that path was still sending unhardened `patchClashConfig` values such as `mixedPort: 7890`
  - as a result, Android VPN mode could start from a hardened profile and then reopen local listeners during the next runtime config sync
- Fix direction:
  - unify Android runtime hardening for both setup/profile generation and live `updateConfig` updates through one shared helper
  - keep UI defaults normal, but apply hardening consistently whenever Android VPN mode is actually active

### Verification Status

- Local Flutter/Dart test execution is not available in the current workstation environment:
  - `flutter`, `dart`, `fvm`, and `melos` are absent from `PATH`
- Existing branch workflow suitable for remote verification:
  - `.github/workflows/android-branch-build.yml`
  - it already runs `flutter test test/common/android_vpn_hardening_test.dart`
  - and builds Android artifacts in GitHub Actions on branch push / manual dispatch
- Anti-regression coverage was extended for the highest-risk follow-up scenarios:
  - Android runtime hardening with `RouteMode.bypassPrivate`
  - ensuring runtime config remains untouched when Android hardening is inactive
  - preserving explicit existing `sniffer` settings while still enforcing domain recovery in hardened Android VPN mode

### Release Packaging Notes

- This fix set is being prepared as release `v0.8.94`.
- Release narrative:
  - keep the localhost leak closed,
  - restore correct Android direct routing on the hardened TUN path,
  - ensure live runtime config updates cannot silently reopen listeners after startup.
- Public-facing docs updated for this release:
  - `CHANGELOG.md`
  - `docs/android-vpn-hardening.md`
  - `README.md`
