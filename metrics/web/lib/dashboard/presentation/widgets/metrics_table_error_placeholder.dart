import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:metrics/base/presentation/widgets/placeholder_list_view_builder.dart';
import 'package:metrics/dashboard/presentation/strings/dashboard_strings.dart';
import 'package:metrics/dashboard/presentation/view_models/build_number_scorecard_view_model.dart';
import 'package:metrics/dashboard/presentation/view_models/build_result_metric_view_model.dart';
import 'package:metrics/dashboard/presentation/view_models/coverage_view_model.dart';
import 'package:metrics/dashboard/presentation/view_models/performance_sparkline_view_model.dart';
import 'package:metrics/dashboard/presentation/view_models/project_metrics_tile_view_model.dart';
import 'package:metrics/dashboard/presentation/view_models/stability_view_model.dart';
import 'package:metrics/dashboard/presentation/widgets/project_metrics_tile.dart';

/// A widget that displays a metrics table error placeholder.
class MetricsTableErrorPlaceholder extends StatelessWidget {
  /// Creates the [MetricsTableErrorPlaceholder].
  const MetricsTableErrorPlaceholder({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PlaceholderListViewBuilder(
      itemHeight: ProjectMetricsTile.height,
      itemBuilder: (_, __) => ProjectMetricsTile(
        projectMetricsViewModel: _projectMetricsTileViewModelPlaceholder(),
      ),
    );
  }

  /// Returns an empty [ProjectMetricsTileViewModel].
  ProjectMetricsTileViewModel _projectMetricsTileViewModelPlaceholder() {
    return ProjectMetricsTileViewModel(
      projectName: DashboardStrings.empty,
      performanceSparkline: PerformanceSparklineViewModel(
        performance: UnmodifiableListView([]),
      ),
      buildNumberMetric: const BuildNumberScorecardViewModel(),
      buildResultMetrics: BuildResultMetricViewModel(
        buildResults: UnmodifiableListView([]),
      ),
      stability: const StabilityViewModel(value: null),
      coverage: const CoverageViewModel(value: null),
    );
  }
}
