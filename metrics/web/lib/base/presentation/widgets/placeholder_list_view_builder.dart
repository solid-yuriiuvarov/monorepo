import 'package:flutter/material.dart';

/// A [ListView.builder] widget that builds placeholder items to fill
/// all available space using the given [itemBuilder].
class PlaceholderListViewBuilder extends StatelessWidget {
  /// A height of a single item.
  final double itemHeight;

  /// An [IndexedWidgetBuilder] used to build the placeholder item.
  final IndexedWidgetBuilder itemBuilder;

  /// Creates a new instance of the [PlaceholderListViewBuilder].
  ///
  /// The [itemHeight] and [itemBuilder] must not be null.
  const PlaceholderListViewBuilder({
    Key key,
    @required this.itemHeight,
    @required this.itemBuilder,
  })  : assert(itemHeight != null),
        assert(itemBuilder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        return ListView.builder(
          itemCount: _calculateItemCount(constraints.maxHeight),
          itemBuilder: itemBuilder,
        );
      },
    );
  }

  /// Calculates a number of items to display based on the given [maxHeight].
  int _calculateItemCount(double maxHeight) {
    final itemCount = maxHeight / itemHeight;

    return itemCount.ceil();
  }
}
