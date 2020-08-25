import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/base/presentation/widgets/placeholder_list_view_builder.dart';

import '../../../test_utils/dimensions_util.dart';

void main() {
  group('PlaceholderListViewBuilder', () {
    testWidgets(
      "throws an AssertionError if the given item height is null",
      (tester) async {
        await tester.pumpWidget(const _PlaceholderListViewBuilderTestbed(
          itemHeight: null,
        ));

        expect(tester.takeException(), isAssertionError);
      },
    );

    testWidgets(
      "throws an AssertionError if the given item builder is null",
      (tester) async {
        await tester.pumpWidget(const _PlaceholderListViewBuilderTestbed(
          itemBuilder: null,
        ));

        expect(tester.takeException(), isAssertionError);
      },
    );

    testWidgets(
      "builds an items using the given item builder",
      (tester) async {
        const item = Text("item");

        await tester.pumpWidget(_PlaceholderListViewBuilderTestbed(
          itemBuilder: (_, __) => item,
        ));

        expect(find.byWidget(item), findsWidgets);
      },
    );

    testWidgets(
      "displays a number of children that can fit on the screen",
      (tester) async {
        const itemHeight = 144.0;
        const height = 300.0;

        final expectedItemCount = (height / itemHeight).ceil();

        DimensionsUtil.setTestWindowSize(height: height);

        await tester.pumpWidget(
          const _PlaceholderListViewBuilderTestbed(
            itemHeight: itemHeight,
          ),
        );

        final actualItemCount =
            tester.widgetList<Text>(find.byType(Text)).length;

        DimensionsUtil.clearTestWindowSize();

        expect(actualItemCount, equals(expectedItemCount));
      },
    );
  });
}

/// A testbed class needed to test the [PlaceholderListViewBuilder] widget.
class _PlaceholderListViewBuilderTestbed extends StatelessWidget {
  /// A height of a single item.
  final double itemHeight;

  /// An [IndexedWidgetBuilder] used to build the placeholder item.
  final IndexedWidgetBuilder itemBuilder;

  /// Creates a new instance of the placeholder list view builder testbed.
  ///
  /// The [itemHeight] defaults to `20.0`.
  /// If the [itemBuilder] is not specified, the default item builder used.
  const _PlaceholderListViewBuilderTestbed({
    Key key,
    this.itemHeight = 20.0,
    this.itemBuilder = _itemBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: PlaceholderListViewBuilder(
          itemHeight: itemHeight,
          itemBuilder: itemBuilder,
        ),
      ),
    );
  }

  static Widget _itemBuilder(_, index) {
    return Text('$index');
  }
}
