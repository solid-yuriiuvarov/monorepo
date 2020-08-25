import 'package:flutter/material.dart';
import 'package:metrics/base/presentation/widgets/placeholder_list_view_builder.dart';
import 'package:metrics/base/presentation/widgets/shimmer_container.dart';
import 'package:metrics/common/presentation/metrics_theme/widgets/metrics_theme.dart';
import 'package:metrics/dashboard/presentation/widgets/project_metrics_tile.dart';

/// A widget that displays a metrics table placeholder with a shimmer effect.
class MetricsTableLoadingPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = MetricsTheme.of(context)
        .projectMetricsTableTheme
        .projectMetricsTilePlaceholderTheme;

    return PlaceholderListViewBuilder(
      itemHeight: ProjectMetricsTile.height,
      itemBuilder: (_, __) => ShimmerContainer(
        height: ProjectMetricsTile.height,
        padding: const EdgeInsets.only(bottom: 4.0),
        shimmerColor: theme.shimmerColor,
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(2.0),
      ),
    );
  }
}
