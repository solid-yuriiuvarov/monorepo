import 'package:flutter/material.dart';

/// A class that stores a style data for sparkline widgets.
class SparklineStyle {
  /// A [Color] of the graph stroke.
  final Color strokeColor;

  /// A fill [Color] of the graph.
  final Color fillColor;

  /// A [TextStyle] of the sparkline texts.
  final TextStyle textStyle;

  /// Creates a [SparklineStyle].
  const SparklineStyle({
    this.strokeColor,
    this.fillColor,
    this.textStyle,
  });
}
