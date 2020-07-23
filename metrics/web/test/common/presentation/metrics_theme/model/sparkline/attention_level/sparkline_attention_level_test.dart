import 'package:flutter/material.dart';
import 'package:metrics/common/presentation/metrics_theme/model/sparkline/attention_level/sparkline_attention_level.dart';
import 'package:metrics/common/presentation/metrics_theme/model/sparkline/style/sparkline_style.dart';
import 'package:test/test.dart';

// https://github.com/software-platform/monorepo/issues/140
// ignore_for_file: prefer_const_constructors

void main() {
  group("SparklineAttentionLevel", () {
    test(
      "creates an instance with a default low attention level style if the parameter is null",
      () {
        final sparklineAttentionLevel = SparklineAttentionLevel(low: null);

        expect(sparklineAttentionLevel.low, isNotNull);
      },
    );

    test(
      "creates an instance with a default medium attention level style if the parameter is null",
      () {
        final sparklineAttentionLevel = SparklineAttentionLevel(medium: null);

        expect(sparklineAttentionLevel.medium, isNotNull);
      },
    );

    test(
      "creates an instance with a default high attention level style if the parameter is null",
      () {
        final sparklineAttentionLevel = SparklineAttentionLevel(high: null);

        expect(sparklineAttentionLevel.high, isNotNull);
      },
    );

    test("creates an instance with the given styles", () {
      const low = SparklineStyle(strokeColor: Colors.black);
      const medium = SparklineStyle(strokeColor: Colors.red);
      const high = SparklineStyle(strokeColor: Colors.green);

      final sparklineAttentionLevel = SparklineAttentionLevel(
        low: low,
        medium: medium,
        high: high,
      );

      expect(sparklineAttentionLevel.low, equals(low));
      expect(sparklineAttentionLevel.medium, equals(medium));
      expect(sparklineAttentionLevel.high, equals(high));
    });
  });
}
