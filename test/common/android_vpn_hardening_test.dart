import 'package:fl_clash/common/android_vpn_hardening.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('android clash config hardening closes local listeners', () {
    const config = ClashConfig(
      port: 8080,
      socksPort: 1080,
      mixedPort: 7890,
      redirPort: 7892,
      tproxyPort: 7893,
      allowLan: true,
      externalController: ExternalControllerStatus.open,
    );

    final hardened = hardenAndroidClashConfig(
      config,
      isAndroid: true,
      vpnEnabled: true,
    );

    expect(hardened.port, 0);
    expect(hardened.socksPort, 0);
    expect(hardened.mixedPort, 0);
    expect(hardened.redirPort, 0);
    expect(hardened.tproxyPort, 0);
    expect(hardened.allowLan, false);
    expect(hardened.externalController, ExternalControllerStatus.close);
  });

  test('android vpn options hardening disables bypass and system proxy', () {
    const options = VpnOptions(
      enable: true,
      port: 7890,
      ipv6: true,
      dnsHijacking: false,
      accessControlProps: AccessControlProps(),
      allowBypass: true,
      systemProxy: true,
      bypassDomain: ['example.com'],
      stack: 'system',
    );

    final hardened = hardenAndroidVpnOptions(options, isAndroid: true);

    expect(hardened.port, 0);
    expect(hardened.allowBypass, false);
    expect(hardened.systemProxy, false);
    expect(hardened.bypassDomain, isEmpty);
  });

  test('android app requests avoid localhost proxy in vpn mode', () {
    expect(
      shouldUseLocalProxyForRequests(
        isAndroid: true,
        vpnEnabled: true,
        isStart: true,
        port: 7890,
      ),
      isFalse,
    );
  });

  test('desktop keeps localhost proxy path when service is running', () {
    expect(
      shouldUseLocalProxyForRequests(
        isAndroid: false,
        vpnEnabled: true,
        isStart: true,
        port: 7890,
      ),
      isTrue,
    );
  });
}
