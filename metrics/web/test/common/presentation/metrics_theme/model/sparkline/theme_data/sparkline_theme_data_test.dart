import 'package:flutter/material.dart';
import 'package:metrics/common/presentation/metrics_theme/model/sparkline/attention_level/sparkline_attention_level.dart';
import 'package:metrics/common/presentation/metrics_theme/model/sparkline/style/sparkline_style.dart';
import 'package:metrics/common/presentation/metrics_theme/model/sparkline/theme_data/sparkline_theme_data.dart';
import 'package:test/test.dart';

// https://github.com/software-platform/monorepo/issues/140
// ignore_for_file: prefer_const_constructors

void main() {
  group("SparklineThemeData", () {
    test(
      "creates an instance with a default attention level if the given attention level is not specified",
      () {
        final sparklineTheme = SparklineThemeData();

        expect(sparklineTheme.attentionLevel, isNotNull);
      },
    );

    test("creates an instance with the given attention level", () {
      final attentionLevel = SparklineAttentionLevel(
        low: SparklineStyle(strokeColor: Colors.red),
        medium: SparklineStyle(fillColor: Colors.black),
        high: SparklineStyle(textStyle: TextStyle(color: Colors.green))
      );

      final sparklineTheme = SparklineThemeData(attentionLevel: attentionLevel);

      expect(sparklineTheme.attentionLevel, equals(attentionLevel));
    });
  });
}
