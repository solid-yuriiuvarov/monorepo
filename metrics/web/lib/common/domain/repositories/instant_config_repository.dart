import 'dart:async';

import 'package:metrics/common/domain/entities/instant_config.dart';

/// A base class for instant config repositories.
///
/// Provides an ability to get the instant config data.
abstract class InstantConfigRepository {
  /// Provides an ability to fetch the [InstantConfig].
  ///
  /// If fetching fails, uses the given [isLoginFormEnabled],
  /// [isFpsMonitorEnabled] and [isRendererDisplayEnabled] default parameters.
  FutureOr<InstantConfig> fetch({
    bool isLoginFormEnabled,
    bool isFpsMonitorEnabled,
    bool isRendererDisplayEnabled,
  });
}
