import 'package:yaml/yaml.dart';

const dashboardInfoNamespace = 'flclash';
const dashboardInfoConfigKey = 'dashboard-info';

enum DashboardInfoLevel { info, success, warning, error }

class DashboardInfoData {
  final String title;
  final String content;
  final DashboardInfoLevel level;

  const DashboardInfoData({
    this.title = '',
    required this.content,
    this.level = DashboardInfoLevel.info,
  });
}

DashboardInfoData? parseDashboardInfoFromProfileYaml(String content) {
  final trimmed = content.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final yamlContent = loadYaml(trimmed);
  if (yamlContent is! Map && yamlContent is! YamlMap) {
    return null;
  }
  final root = _asStringKeyedMap(yamlContent);
  final namespace = _asStringKeyedMap(root[dashboardInfoNamespace]);
  return parseDashboardInfo(namespace[dashboardInfoConfigKey]);
}

DashboardInfoData? parseDashboardInfo(Object? value) {
  if (value is String) {
    final content = value.trim();
    if (content.isEmpty) {
      return null;
    }
    return DashboardInfoData(content: content);
  }
  if (value is! Map && value is! YamlMap) {
    return null;
  }
  final map = _asStringKeyedMap(value);
  final content = _stringValue(
    map['content'] ?? map['message'] ?? map['text'] ?? map['body'],
  );
  if (content == null || content.trim().isEmpty) {
    return null;
  }
  return DashboardInfoData(
    title: _stringValue(map['title']) ?? '',
    content: content.trim(),
    level: _parseDashboardInfoLevel(map['level'] ?? map['type']),
  );
}

DashboardInfoLevel _parseDashboardInfoLevel(Object? value) {
  final normalized = _stringValue(value)?.trim().toLowerCase();
  return switch (normalized) {
    'success' => DashboardInfoLevel.success,
    'warning' => DashboardInfoLevel.warning,
    'error' => DashboardInfoLevel.error,
    _ => DashboardInfoLevel.info,
  };
}

String? _stringValue(Object? value) {
  if (value == null) {
    return null;
  }
  final normalized = value.toString().trim();
  return normalized.isEmpty ? null : normalized;
}

Map<String, dynamic> _asStringKeyedMap(Object? value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  if (value is YamlMap) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const <String, dynamic>{};
}
