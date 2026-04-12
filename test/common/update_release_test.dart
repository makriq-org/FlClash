import 'package:fl_clash/common/update.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('android release asset selection', () {
    final release = AppRelease(
      tagName: 'v0.8.95',
      body: '',
      htmlUrl: 'https://github.com/makriq3/FlClash/releases/tag/v0.8.95',
      assets: [
        ReleaseAsset(
          name: 'FlClash-0.8.95-android-arm64-v8a.apk',
          browserDownloadUrl: 'https://example.com/arm64.apk',
          size: 1,
          digest:
              'sha256:1111111111111111111111111111111111111111111111111111111111111111',
        ),
        ReleaseAsset(
          name: 'FlClash-0.8.95-android-arm64-v8a.apk.sha256',
          browserDownloadUrl: 'https://example.com/arm64.apk.sha256',
          size: 1,
        ),
        ReleaseAsset(
          name: 'FlClash-0.8.95-android-armeabi-v7a.apk',
          browserDownloadUrl: 'https://example.com/armv7.apk',
          size: 1,
        ),
      ],
    );

    test('selects the first compatible abi from device preference order', () {
      final selected = selectAndroidReleaseAsset(
        release,
        supportedAbis: const ['x86_64', 'arm64-v8a', 'armeabi-v7a'],
      );

      expect(selected, isNotNull);
      expect(selected!.abi, 'arm64-v8a');
      expect(selected.apkAsset.name, contains('arm64-v8a'));
      expect(selected.checksumAsset?.name, endsWith('.apk.sha256'));
    });

    test('returns null when release has no compatible abi', () {
      final selected = selectAndroidReleaseAsset(
        release,
        supportedAbis: const ['x86_64'],
      );

      expect(selected, isNull);
    });
  });

  test('parses sha256 sidecar file content', () {
    final parsed = parseSha256Content(
      'c330912450ff08461b11f755bc3733c6b6a9c71396324a2e3e40d1589bdff62e  FlClash.apk',
    );

    expect(
      parsed,
      'c330912450ff08461b11f755bc3733c6b6a9c71396324a2e3e40d1589bdff62e',
    );
  });
}
