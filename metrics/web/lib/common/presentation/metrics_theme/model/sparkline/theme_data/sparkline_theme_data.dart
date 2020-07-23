import 'package:meta/meta.dart';
import 'package:metrics/common/presentation/metrics_theme/model/attention_level_theme_data.dart';
import 'package:metrics/common/presentation/metrics_theme/model/sparkline/attention_level/sparkline_attention_level.dart';

/// An [AttentionLevelThemeData] for sparkline widgets.
///
/// Stores the theme data for sparkline graph widgets with different attention levels.
@immutable
class SparklineThemeData
    extends AttentionLevelThemeData<SparklineAttentionLevel> {

  /// Creates a [SparklineThemeData] with the given [attentionLevel].
  ///
  /// If the given [attentionLevel] is null, the [SparklineAttentionLevel] used.
  const SparklineThemeData({SparklineAttentionLevel attentionLevel})
      : super(attentionLevel ?? const SparklineAttentionLevel());
}
