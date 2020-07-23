import 'package:metrics/common/presentation/metrics_theme/model/sparkline/style/sparkline_style.dart';

/// A class that stores the [SparklineStyle]s for the different
/// appearance of the sparkline widgets within the application.
class SparklineAttentionLevel {
  /// A [SparklineStyle] for sparkline widgets with a low visual attention level.
  /// Usually used on a small, dim graphs like performance sparkline.
  final SparklineStyle low;

  /// A [SparklineStyle] for sparkline widgets with a medium visual attention level.
  /// Usually used on a big, but not so colored sparklines.
  final SparklineStyle medium;

  /// A [SparklineStyle] for sparkline widgets with a high visual attention level.
  /// Usually used on a big, colorful sparkline widgets.
  final SparklineStyle high;

  /// Creates an instance of the [SparklineAttentionLevel].
  ///
  /// If the [low], [medium], or [high] is null, the [SparklineStyle] used.
  const SparklineAttentionLevel({
    SparklineStyle low,
    SparklineStyle medium,
    SparklineStyle high,
  })  : low = low ?? const SparklineStyle(),
        medium = medium ?? const SparklineStyle(),
        high = high ?? const SparklineStyle();
}
