import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:fl_clash/common/print.dart';
import 'package:fl_clash/common/preferences.dart';
import 'package:fl_clash/common/request.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/foundation.dart';

const profileAppliedDiagnosticsEndpoint = 'https://diag.makriq.com/v1/report';
const profileAppliedDiagnosticsMinInterval = Duration(days: 1);

@visibleForTesting
List<String> resolveExcludedPackagesForDiagnostics(
  AccessControlProps? accessControlProps,
) {
  if (accessControlProps == null || !accessControlProps.enable) {
    return const [];
  }
  if (accessControlProps.mode != AccessControlMode.rejectSelected) {
    return const [];
  }
  return accessControlProps.rejectList.toSet().toList()..sort();
}

@visibleForTesting
String buildProfileAppliedDiagnosticsSignature({
  required String appVersion,
  required int? profileId,
  required String profileName,
  required String? profileUpdatedAt,
  required RouteMode routeMode,
  required List<String> excludedPackages,
}) {
  final payload = jsonEncode({
    'app_version': appVersion,
    'profile_id': profileId,
    'profile_name': profileName,
    'profile_updated_at': profileUpdatedAt,
    'route_mode': routeMode.name,
    'excluded_packages': excludedPackages,
  });
  return sha256.convert(utf8.encode(payload)).toString();
}

@visibleForTesting
bool shouldSendProfileAppliedDiagnostics({
  required String nextSignature,
  required String? lastSignature,
  required DateTime? lastAttemptedAt,
  required DateTime now,
}) {
  if (nextSignature != lastSignature) {
    return true;
  }
  if (lastAttemptedAt == null) {
    return true;
  }
  return now.difference(lastAttemptedAt) >=
      profileAppliedDiagnosticsMinInterval;
}

class ProfileAppliedDiagnosticsReporter {
  const ProfileAppliedDiagnosticsReporter();

  Future<void> report({
    required Profile profile,
    required RouteMode routeMode,
    required AccessControlProps? accessControlProps,
    required bool appListPermission,
  }) async {
    final excludedPackages = resolveExcludedPackagesForDiagnostics(
      accessControlProps,
    );
    final appVersion = [
      globalState.packageInfo.version,
      globalState.packageInfo.buildNumber,
    ].where((item) => item.trim().isNotEmpty).join('+');
    final profileUpdatedAt = profile.lastUpdateDate?.toUtc().toIso8601String();
    final signature = buildProfileAppliedDiagnosticsSignature(
      appVersion: appVersion,
      profileId: profile.id,
      profileName: profile.realLabel,
      profileUpdatedAt: profileUpdatedAt,
      routeMode: routeMode,
      excludedPackages: excludedPackages,
    );
    final now = DateTime.now().toUtc();
    final lastState = await preferences.getProfileAppliedDiagnosticsState();
    if (!shouldSendProfileAppliedDiagnostics(
      nextSignature: signature,
      lastSignature: lastState.signature,
      lastAttemptedAt: lastState.attemptedAt,
      now: now,
    )) {
      return;
    }

    final reportId = await preferences.getOrCreateDiagnosticsReportId();
    final androidDeviceInfo = await _getAndroidDeviceInfo();
    final body = {
      'report_id': reportId,
      'created_at': now.toIso8601String(),
      'os_version': androidDeviceInfo.osVersion,
      'device': androidDeviceInfo.device,
      'app_version': appVersion,
      'profile_name': profile.realLabel,
      'profile_updated_at': profileUpdatedAt,
      'route_mode': routeMode.name,
      'app_list_permission': appListPermission,
      'excluded_packages': excludedPackages,
    };
    await preferences.setProfileAppliedDiagnosticsState(
      signature: signature,
      attemptedAt: now,
    );
    try {
      await request.dio
          .post(
            profileAppliedDiagnosticsEndpoint,
            data: body,
            options: Options(
              contentType: Headers.jsonContentType,
              sendTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            ),
          )
          .timeout(const Duration(seconds: 10));
    } catch (error) {
      commonPrint.log(
        'profile applied diagnostics report failed: $error',
        logLevel: LogLevel.warning,
      );
    }
  }

  Future<_AndroidDeviceInfo> _getAndroidDeviceInfo() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      final manufacturer = info.manufacturer.trim();
      final model = info.model.trim();
      final device = [
        manufacturer,
        model,
      ].where((item) => item.isNotEmpty).join(' ').trim();
      return _AndroidDeviceInfo(
        osVersion:
            'Android ${info.version.release} (SDK ${info.version.sdkInt})',
        device: device.isEmpty ? info.device : device,
      );
    } catch (_) {
      return const _AndroidDeviceInfo(osVersion: 'Android', device: '');
    }
  }
}

class _AndroidDeviceInfo {
  const _AndroidDeviceInfo({required this.osVersion, required this.device});

  final String osVersion;
  final String device;
}

const profileAppliedDiagnosticsReporter = ProfileAppliedDiagnosticsReporter();
