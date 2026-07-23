import 'package:fl_clash/common/dashboard_info.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses dashboard info widget config from profile yaml map', () {
    final info = parseDashboardInfoFromProfileYaml('''
flclash:
  dashboard-info:
    title: Maintenance
    content: Server reboot at 03:00 UTC.
    level: warning
''');

    expect(info, isNotNull);
    expect(info?.title, 'Maintenance');
    expect(info?.content, 'Server reboot at 03:00 UTC.');
    expect(info?.level, DashboardInfoLevel.warning);
  });

  test('parses dashboard info widget config from shorthand string', () {
    final info = parseDashboardInfoFromProfileYaml('''
flclash:
  dashboard-info: Simple text for users
''');

    expect(info, isNotNull);
    expect(info?.title, isEmpty);
    expect(info?.content, 'Simple text for users');
    expect(info?.level, DashboardInfoLevel.info);
  });

  test('returns null when dashboard info content is empty', () {
    final info = parseDashboardInfoFromProfileYaml('''
flclash:
  dashboard-info:
    title: Empty
    content: "   "
''');

    expect(info, isNull);
  });

  test('dashboard widgets config always includes dashboard info widget', () {
    final widgets = dashboardWidgetsSafeFormJson([
      'networkSpeed',
      'outboundMode',
      'trafficUsage',
    ]);

    expect(widgets, contains(DashboardWidget.dashboardInfo));
    expect(widgets.indexOf(DashboardWidget.dashboardInfo), 1);
    expect(widgets.first, DashboardWidget.networkSpeed);
  });
}
