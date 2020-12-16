import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:metrics/auth/presentation/strings/auth_strings.dart';
import 'package:metrics/auth/presentation/widgets/auth_form.dart';
import 'package:metrics/base/presentation/graphs/circle_percentage.dart';
import 'package:metrics/common/presentation/strings/common_strings.dart';
import 'package:metrics/dashboard/presentation/pages/dashboard_page.dart';
import 'package:metrics/dashboard/presentation/strings/dashboard_strings.dart';
import 'package:metrics/dashboard/presentation/widgets/build_number_scorecard.dart';
import 'package:metrics/dashboard/presentation/widgets/build_result_bar_graph.dart';
import 'package:metrics/dashboard/presentation/widgets/performance_sparkline_graph.dart';
import 'package:metrics/dashboard/presentation/widgets/project_metrics_tile.dart';
import 'package:metrics/dashboard/presentation/widgets/projects_search_input.dart';
import 'package:metrics/main.dart';

import 'arguments/model/user_credentials.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("LoginPage", () {
    testWidgets("shows an authentication form", (WidgetTester tester) async {
      await _pumpApp(tester);

      await _authFormExists(tester);
    });

    testWidgets("can authenticate in the app using an email and a password",
        (WidgetTester tester) async {
      await _pumpApp(tester);

      await _login(tester);
      await tester.pumpAndSettle();

      expect(find.byType(DashboardPage), findsOneWidget);
    });

    testWidgets("can log out from the app", (WidgetTester tester) async {
      await _pumpApp(tester);

      await tester.tap(find.byTooltip(CommonStrings.openUserMenu));
      await tester.pumpAndSettle();

      await tester.tap(find.text(CommonStrings.logOut));
      await tester.pumpAndSettle();

      await _authFormExists(tester);
    });
  });

  group(
    "DashboardPage",
    () {
      testWidgets("loads and shows the projects", (WidgetTester tester) async {
        await _pumpApp(tester);

        await _login(tester);
        await tester.pumpAndSettle();

        expect(find.byType(ProjectMetricsTile), findsWidgets);
      });

      testWidgets(
        "loads and displays coverage metric",
        (WidgetTester tester) async {
          await _pumpApp(tester);

          expect(find.text(DashboardStrings.coverage), findsWidgets);
          expect(find.byType(CirclePercentage), findsWidgets);
        },
      );

      testWidgets(
        "loads and displays the performance metric",
        (WidgetTester tester) async {
          await _pumpApp(tester);

          expect(find.text(DashboardStrings.performance), findsWidgets);
          expect(find.byType(PerformanceSparklineGraph), findsWidgets);
        },
      );

      testWidgets(
        "loads and shows the build number metric",
        (WidgetTester tester) async {
          await _pumpApp(tester);

          expect(find.text(DashboardStrings.builds), findsWidgets);
          expect(find.byType(BuildNumberScorecard), findsWidgets);
        },
      );

      testWidgets(
        "loads and shows the build result metrics",
        (WidgetTester tester) async {
          await _pumpApp(tester);

          expect(find.byType(BuildResultBarGraph), findsWidgets);
        },
      );

      testWidgets("shows a search project input", (WidgetTester tester) async {
        await _pumpApp(tester);

        expect(find.byType(ProjectSearchInput), findsWidgets);
      });

      testWidgets(
        "project search input filters list of projects",
        (WidgetTester tester) async {
          await _pumpApp(tester);

          final noProjectsTextFinder =
              find.text(DashboardStrings.noConfiguredProjects);
          final searchInputFinder = find.byType(ProjectSearchInput);
          final noSearchResultsTextFinder =
              find.text(DashboardStrings.noSearchResults);

          expect(noProjectsTextFinder, findsNothing);

          await tester.enterText(
            searchInputFinder,
            '_test_filters_project_name_',
          );
          await tester.pumpAndSettle();

          expect(noSearchResultsTextFinder, findsOneWidget);
        },
      );
    },
  );
}

Future<void> _login(WidgetTester tester) async {
  final environment = Platform.environment;
  final credentials = UserCredentials.fromMap(environment);

  final emailFinder = find.byKey(const Key(AuthStrings.email));
  final passwordFinder = find.byKey(const Key(AuthStrings.password));
  final signButtonFinder = find.byKey(const Key(AuthStrings.signIn));

  await tester.enterText(emailFinder, credentials.email);
  await tester.enterText(passwordFinder, credentials.password);
  await tester.tap(signButtonFinder);
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(MetricsApp());
  await tester.pumpAndSettle();
}

Future<void> _authFormExists(WidgetTester tester) async {
  expect(find.byType(AuthForm), findsOneWidget);
}
