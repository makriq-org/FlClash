import 'package:fl_clash/common/diagnostics.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('profile applied diagnostics', () {
    test('sends immediately when the state signature changes', () {
      final now = DateTime.utc(2026, 6, 2, 12);

      expect(
        shouldSendProfileAppliedDiagnostics(
          nextSignature: 'next',
          lastSignature: 'last',
          lastAttemptedAt: now,
          now: now,
        ),
        isTrue,
      );
    });

    test('limits unchanged reports to once per day', () {
      final now = DateTime.utc(2026, 6, 2, 12);

      expect(
        shouldSendProfileAppliedDiagnostics(
          nextSignature: 'same',
          lastSignature: 'same',
          lastAttemptedAt: now.subtract(const Duration(hours: 23)),
          now: now,
        ),
        isFalse,
      );
      expect(
        shouldSendProfileAppliedDiagnostics(
          nextSignature: 'same',
          lastSignature: 'same',
          lastAttemptedAt: now.subtract(const Duration(days: 1)),
          now: now,
        ),
        isTrue,
      );
    });

    test('reports only explicitly rejected packages', () {
      expect(
        resolveExcludedPackagesForDiagnostics(
          AccessControlProps(
            enable: true,
            mode: AccessControlMode.rejectSelected,
            rejectList: ['org.mozilla.firefox', 'com.android.chrome'],
          ),
        ),
        ['com.android.chrome', 'org.mozilla.firefox'],
      );

      expect(
        resolveExcludedPackagesForDiagnostics(
          AccessControlProps(
            enable: true,
            mode: AccessControlMode.acceptSelected,
            acceptList: ['org.telegram.messenger'],
          ),
        ),
        isEmpty,
      );
    });

    test(
      'signature changes on version, profile, route mode and exclusions',
      () {
        String buildSignature({
          String appVersion = '0.9.21+2026060201',
          int? profileId = 1,
          String profileName = 'main',
          RouteMode routeMode = RouteMode.config,
          List<String> excludedPackages = const ['com.android.chrome'],
        }) {
          return buildProfileAppliedDiagnosticsSignature(
            appVersion: appVersion,
            profileId: profileId,
            profileName: profileName,
            profileUpdatedAt: '2026-06-02T09:00:00.000Z',
            routeMode: routeMode,
            excludedPackages: excludedPackages,
          );
        }

        final base = buildSignature();

        expect(buildSignature(appVersion: '0.9.22+1'), isNot(base));
        expect(buildSignature(profileId: 2), isNot(base));
        expect(buildSignature(routeMode: RouteMode.bypassPrivate), isNot(base));
        expect(
          buildSignature(excludedPackages: ['org.mozilla.firefox']),
          isNot(base),
        );
      },
    );
  });
}
