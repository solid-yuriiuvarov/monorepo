import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/base/presentation/widgets/placeholder_list_view_builder.dart';
import 'package:metrics/common/presentation/metrics_theme/config/dimensions_config.dart';
import 'package:metrics/dashboard/presentation/strings/dashboard_strings.dart';
import 'package:metrics/dashboard/presentation/view_models/build_number_scorecard_view_model.dart';
import 'package:metrics/dashboard/presentation/view_models/build_result_metric_view_model.dart';
import 'package:metrics/dashboard/presentation/view_models/coverage_view_model.dart';
import 'package:metrics/dashboard/presentation/view_models/performance_sparkline_view_model.dart';
import 'package:metrics/dashboard/presentation/view_models/project_metrics_tile_view_model.dart';
import 'package:metrics/dashboard/presentation/view_models/stability_view_model.dart';
import 'package:metrics/dashboard/presentation/widgets/metrics_table_error_placeholder.dart';
import 'package:metrics/dashboard/presentation/widgets/project_metrics_tile.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../../../test_utils/dimensions_util.dart';

void main() {
  group("MetricsTableErrorPlaceholder", () {
    setUpAll(() {
      DimensionsUtil.setTestWindowSize(width: DimensionsConfig.contentWidth);
    });

    tearDownAll(() {
      DimensionsUtil.clearTestWindowSize();
    });

    testWidgets(
      "displays the placeholder list view builder",
      (tester) async {
        await mockNetworkImagesFor(
          () => tester.pumpWidget(_MetricsTablePlaceholderTestbed()),
        );

        expect(find.byType(PlaceholderListViewBuilder), findsOneWidget);
      },
    );

    testWidgets(
      "displays project metrics tiles with empty metrics",
      (tester) async {
        final emptyProjectMetricsViewModel = ProjectMetricsTileViewModel(
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

        await mockNetworkImagesFor(
          () => tester.pumpWidget(_MetricsTablePlaceholderTestbed()),
        );

        final metricsTiles = tester
            .widgetList<ProjectMetricsTile>(find.byType(ProjectMetricsTile));

        final projectMetrics =
            metricsTiles.map((tile) => tile.projectMetricsViewModel);

        final isEmptyMetrics = projectMetrics.every(
          (metric) => metric == emptyProjectMetricsViewModel,
        );

        expect(isEmptyMetrics, isTrue);
      },
    );
  });
}

/// A testbed class required to test the [MetricsTableErrorPlaceholder] widget.
class _MetricsTablePlaceholderTestbed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: MetricsTableErrorPlaceholder(),
      ),
    );
  }
}
