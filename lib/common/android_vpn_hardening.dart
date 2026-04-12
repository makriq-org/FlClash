import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';

bool shouldApplyAndroidVpnHardening({
  required bool isAndroid,
  required bool vpnEnabled,
}) {
  return isAndroid && vpnEnabled;
}

ClashConfig hardenAndroidClashConfig(
  ClashConfig config, {
  required bool isAndroid,
  required bool vpnEnabled,
}) {
  if (!shouldApplyAndroidVpnHardening(
    isAndroid: isAndroid,
    vpnEnabled: vpnEnabled,
  )) {
    return config;
  }
  return config.copyWith(
    port: 0,
    socksPort: 0,
    mixedPort: 0,
    redirPort: 0,
    tproxyPort: 0,
    allowLan: false,
    externalController: ExternalControllerStatus.close,
  );
}

VpnOptions hardenAndroidVpnOptions(
  VpnOptions options, {
  required bool isAndroid,
}) {
  if (!shouldApplyAndroidVpnHardening(
    isAndroid: isAndroid,
    vpnEnabled: options.enable,
  )) {
    return options;
  }
  return options.copyWith(
    allowBypass: false,
    systemProxy: false,
    bypassDomain: const [],
    port: 0,
  );
}

bool shouldUseLocalProxyForRequests({
  required bool isAndroid,
  required bool vpnEnabled,
  required bool isStart,
  required int port,
}) {
  if (!isStart || port <= 0) {
    return false;
  }
  return !shouldApplyAndroidVpnHardening(
    isAndroid: isAndroid,
    vpnEnabled: vpnEnabled,
  );
}
