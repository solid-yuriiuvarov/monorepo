import 'package:flutter/material.dart';
import 'package:metrics/common/presentation/metrics_theme/model/sparkline/style/sparkline_style.dart';
import 'package:test/test.dart';

// https://github.com/software-platform/monorepo/issues/140
// ignore_for_file: prefer_const_constructors

void main() {
  group("SparklineStyle", () {
    test("creates an instance with the given parameters", () {
      const strokeColor = Colors.red;
      const fillColor = Colors.green;
      const textStyle = TextStyle(color: Colors.black);

      final sparklineStyle = SparklineStyle(
        strokeColor: strokeColor,
        fillColor: fillColor,
        textStyle: textStyle,
      );

      expect(sparklineStyle.strokeColor, equals(strokeColor));
      expect(sparklineStyle.fillColor, equals(fillColor));
      expect(sparklineStyle.textStyle, equals(textStyle));
    });
  });
}
