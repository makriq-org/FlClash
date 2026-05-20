import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardInfoWidget extends ConsumerWidget {
  const DashboardInfoWidget({super.key});

  Color _getAccentColor(BuildContext context, DashboardInfoLevel level) {
    return switch (level) {
      DashboardInfoLevel.info => context.colorScheme.primary,
      DashboardInfoLevel.success => Colors.green.shade600,
      DashboardInfoLevel.warning => Colors.orange.shade700,
      DashboardInfoLevel.error => context.colorScheme.error,
    };
  }

  IconData _getIcon(DashboardInfoLevel level) {
    return switch (level) {
      DashboardInfoLevel.info => Icons.info_outline,
      DashboardInfoLevel.success => Icons.check_circle_outline,
      DashboardInfoLevel.warning => Icons.warning_amber_rounded,
      DashboardInfoLevel.error => Icons.error_outline,
    };
  }

  String _getLabel(DashboardInfoLevel level) {
    return switch (level) {
      DashboardInfoLevel.info => 'INFO',
      DashboardInfoLevel.success => 'OK',
      DashboardInfoLevel.warning => 'WARN',
      DashboardInfoLevel.error => 'ERROR',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardInfo = ref.watch(dashboardProfileInfoProvider).asData?.value;
    if (dashboardInfo == null) {
      return const SizedBox.shrink();
    }
    final accentColor = _getAccentColor(context, dashboardInfo.level);
    return SizedBox(
      height: getWidgetHeight(2),
      child: CommonCard(
        onPressed: () {},
        info: const Info(label: 'Info', iconData: Icons.campaign_outlined),
        child: Padding(
          padding: baseInfoEdgeInsets.copyWith(top: 8, bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: ShapeDecoration(
                  color: accentColor,
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getIcon(dashboardInfo.level),
                          size: 18,
                          color: accentColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dashboardInfo.title.isNotEmpty
                                ? dashboardInfo.title
                                : 'User message',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleSmall?.copyWith(
                              color: context.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: ShapeDecoration(
                            color: accentColor.opacity12,
                            shape: RoundedSuperellipseBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            _getLabel(dashboardInfo.level),
                            style: context.textTheme.labelSmall?.copyWith(
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Text(
                        dashboardInfo.content,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
