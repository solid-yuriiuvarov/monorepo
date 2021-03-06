import 'package:metrics/dashboard/presentation/widgets/strategy/project_build_status_image_strategy.dart';
import 'package:metrics_core/metrics_core.dart';
import 'package:test/test.dart';

// https://github.com/platform-platform/monorepo/issues/140
// ignore_for_file: prefer_const_constructors

void main() {
  group("ProjectBuildStatusImageStrategy", () {
    const successfulImage = "icons/successful_status.svg";
    const failedImage = "icons/failed_status.svg";
    const unknownImage = "icons/unknown_status.svg";
    final strategy = ProjectBuildStatusImageStrategy();

    test(
      ".getImageAsset() returns the successful image if the given build status is successful",
      () {
        final actualImage = strategy.getImageAsset(BuildStatus.successful);

        expect(actualImage, equals(successfulImage));
      },
    );

    test(
      ".getImageAsset() returns the failed image if the given build status is failed",
      () {
        final actualImage = strategy.getImageAsset(BuildStatus.failed);

        expect(actualImage, equals(failedImage));
      },
    );

    test(
      ".getImageAsset() returns the unknown image if the given build status is unknown",
      () {
        final actualImage = strategy.getImageAsset(BuildStatus.unknown);

        expect(actualImage, equals(unknownImage));
      },
    );

    test(
      ".getImageAsset() returns null if the given build status is null",
      () {
        final actualImage = strategy.getImageAsset(null);

        expect(actualImage, isNull);
      },
    );
  });
}
