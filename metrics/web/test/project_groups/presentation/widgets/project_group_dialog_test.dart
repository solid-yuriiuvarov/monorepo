import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/base/presentation/widgets/decorated_container.dart';
import 'package:metrics/base/presentation/widgets/info_dialog.dart';
import 'package:metrics/base/presentation/widgets/value_form_field.dart';
import 'package:metrics/common/presentation/button/widgets/metrics_inactive_button.dart';
import 'package:metrics/common/presentation/button/widgets/metrics_positive_button.dart';
import 'package:metrics/common/presentation/metrics_theme/model/metrics_theme_data.dart';
import 'package:metrics/common/presentation/metrics_theme/model/project_group_dialog_theme_data.dart';
import 'package:metrics/common/presentation/strings/common_strings.dart';
import 'package:metrics/common/presentation/toast/widgets/negative_toast.dart';
import 'package:metrics/common/presentation/toast/widgets/positive_toast.dart';
import 'package:metrics/common/presentation/widgets/metrics_text_form_field.dart';
import 'package:metrics/project_groups/domain/value_objects/project_group_projects.dart';
import 'package:metrics/project_groups/presentation/state/project_groups_notifier.dart';
import 'package:metrics/project_groups/presentation/strings/project_groups_strings.dart';
import 'package:metrics/project_groups/presentation/validators/project_group_name_validator.dart';
import 'package:metrics/project_groups/presentation/validators/project_group_projects_validator.dart';
import 'package:metrics/project_groups/presentation/view_models/project_group_dialog_view_model.dart';
import 'package:metrics/project_groups/presentation/widgets/project_checkbox_list.dart';
import 'package:metrics/project_groups/presentation/widgets/project_group_dialog.dart';
import 'package:metrics/project_groups/presentation/widgets/strategy/project_group_dialog_strategy.dart';
import 'package:mockito/mockito.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../../../test_utils/metrics_themed_testbed.dart';
import '../../../test_utils/project_groups_notifier_mock.dart';
import '../../../test_utils/test_injection_container.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("ProjectGroupDialog", () {
    const title = 'title';
    const buttonText = 'testText';
    const loadingText = 'loading...';
    const backgroundColor = Colors.red;
    const contentBorderColor = Colors.yellow;
    const testText = "test";

    final searchFieldFinder = find.byWidgetPredicate(
      (widget) {
        return widget is MetricsTextFormField &&
            widget.hint == CommonStrings.searchForProject;
      },
    );

    Future<void> closeDialog(WidgetTester tester) async {
      final infoDialog = tester.widget<InfoDialog>(find.byType(InfoDialog));
      final closeIcon = infoDialog.closeIcon;
      await tester.tap(find.byWidget(closeIcon));
    }

    final groupNameFieldFinder = find.byWidgetPredicate(
      (widget) {
        return widget is MetricsTextFormField &&
            widget.hint == ProjectGroupsStrings.nameYourGroup;
      },
    );

    const titleTextStyle = TextStyle(
      color: Colors.grey,
    );
    const counterTextStyle = TextStyle(
      color: Colors.blue,
    );
    const toastMessage = 'toast message';

    final projectGroupDialogViewModel = ProjectGroupDialogViewModel(
      id: "id",
      name: "name",
      selectedProjectIds: UnmodifiableListView<String>(["id"]),
    );

    const theme = MetricsThemeData(
      projectGroupDialogTheme: ProjectGroupDialogThemeData(
        backgroundColor: backgroundColor,
        contentBorderColor: contentBorderColor,
        titleTextStyle: titleTextStyle,
        counterTextStyle: counterTextStyle,
      ),
    );

    final strategy = ProjectGroupDialogStrategyMock();

    ProjectGroupsNotifier projectGroupsNotifier;

    setUp(() {
      when(strategy.title).thenReturn(title);
      when(strategy.text).thenReturn(buttonText);
      when(strategy.loadingText).thenReturn(loadingText);
      when(strategy.getSuccessfulActionMessage(any)).thenReturn(toastMessage);

      projectGroupsNotifier = ProjectGroupsNotifierMock();

      when(projectGroupsNotifier.projectGroupDialogViewModel)
          .thenReturn(projectGroupDialogViewModel);
    });

    tearDown(() {
      reset(strategy);
      reset(projectGroupsNotifier);
    });

    testWidgets(
      "throws an AssertionError if the given strategy is null",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _ProjectGroupDialogTestbed(
            strategy: null,
          ));
        });

        expect(tester.takeException(), isAssertionError);
      },
    );

    testWidgets(
      "applies the background color from the metrics theme",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            theme: theme,
            strategy: strategy,
          ));
        });

        final infoDialog = tester.widget<InfoDialog>(
          find.byType(InfoDialog),
        );

        expect(infoDialog.backgroundColor, equals(backgroundColor));
      },
    );

    testWidgets(
      "applies the title text style from the metrics theme",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            theme: theme,
            strategy: strategy,
          ));
        });

        final titleWidget = tester.widget<Text>(
          find.text(title),
        );

        expect(titleWidget.style, equals(titleTextStyle));
      },
    );

    testWidgets(
      "applies the counter text style from the metrics theme",
      (WidgetTester tester) async {
        final selectedProjects = ['1'];
        final projectGroup = ProjectGroupDialogViewModel(
          selectedProjectIds: UnmodifiableListView(selectedProjects),
        );

        final notifier = ProjectGroupsNotifierMock();

        when(notifier.projectGroupDialogViewModel).thenReturn(projectGroup);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            theme: theme,
            strategy: strategy,
            projectGroupsNotifier: notifier,
          ));
        });

        final titleWidget = tester.widget<Text>(
          find.text(ProjectGroupsStrings.getSelectedCount(
            selectedProjects.length,
          )),
        );

        expect(titleWidget.style, equals(counterTextStyle));
      },
    );

    testWidgets(
      "applies the content border color from the metrics theme",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            theme: theme,
            strategy: strategy,
          ));
        });

        final contentContainer = tester.widget<DecoratedContainer>(
          find.byWidgetPredicate((widget) =>
              widget is DecoratedContainer && widget.child is Column),
        );

        final decoration = contentContainer.decoration as BoxDecoration;
        final border = decoration.border as Border;

        expect(border.top.color, equals(contentBorderColor));
        expect(border.bottom.color, equals(contentBorderColor));
        expect(border.left.color, equals(contentBorderColor));
        expect(border.right.color, equals(contentBorderColor));
      },
    );

    testWidgets(
      "displays the title from the given strategy",
      (WidgetTester tester) async {
        const title = "test title";

        when(strategy.title).thenReturn(title);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
          ));
        });

        expect(find.text(title), findsOneWidget);
      },
    );

    testWidgets(
      "applies the text from the given strategy to the action button",
      (WidgetTester tester) async {
        const text = "test title";

        when(strategy.text).thenReturn(text);
        when(projectGroupsNotifier.projectGroupDialogViewModel)
            .thenReturn(projectGroupDialogViewModel);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        expect(
          find.widgetWithText(MetricsInactiveButton, text),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      "displays the positive create group button when the group name and the number of selected projects in project checkbox list are both valid",
      (tester) async {
        when(projectGroupsNotifier.projectGroupDialogViewModel)
            .thenReturn(projectGroupDialogViewModel);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        await tester.enterText(groupNameFieldFinder, 'some group name');
        await tester.pump();

        expect(find.byType(MetricsPositiveButton), findsOneWidget);
      },
    );

    testWidgets(
      "displays the inactive create group button when the group name is not valid",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
          ));
        });

        await tester.enterText(groupNameFieldFinder, '');
        await tester.pumpAndSettle();

        expect(find.byType(MetricsInactiveButton), findsOneWidget);
      },
    );

    testWidgets(
      "displays the inactive create group button when the number of selected projects is > 20",
      (tester) async {
        final List<String> selectedIds = [];
        for (int i = 0; i <= 21; ++i) {
          selectedIds.add("some value");
        }
        final projectDialogViewModel = ProjectGroupDialogViewModel(
          id: "id",
          name: "name",
          selectedProjectIds: UnmodifiableListView<String>(selectedIds),
        );

        when(projectGroupsNotifier.projectGroupDialogViewModel)
            .thenReturn(projectDialogViewModel);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        expect(find.byType(MetricsInactiveButton), findsOneWidget);
      },
    );

    testWidgets(
      "displays the inactive create group button when there are no selected projects",
      (tester) async {
        final projectDialogViewModel = ProjectGroupDialogViewModel(
          id: "id",
          name: "name",
          selectedProjectIds: UnmodifiableListView<String>([]),
        );

        when(projectGroupsNotifier.projectGroupDialogViewModel)
            .thenReturn(projectDialogViewModel);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        expect(find.byType(MetricsInactiveButton), findsOneWidget);
      },
    );

    testWidgets(
      "displays the inactive create group button when the group name is not valid and the number of selected projects is valid",
      (tester) async {
        when(projectGroupsNotifier.projectGroupDialogViewModel)
            .thenReturn(projectGroupDialogViewModel);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
          ));
        });

        await tester.enterText(groupNameFieldFinder, '');
        await tester.pumpAndSettle();

        expect(find.byType(MetricsInactiveButton), findsOneWidget);
      },
    );

    testWidgets(
      "displays the inactive create group button when the number of selected projects is not valid and the group name is valid",
      (tester) async {
        final projectDialogViewModel = ProjectGroupDialogViewModel(
          id: "id",
          name: "name",
          selectedProjectIds: UnmodifiableListView<String>([]),
        );
        when(projectGroupsNotifier.projectGroupDialogViewModel)
            .thenReturn(projectDialogViewModel);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
          ));
        });

        await tester.enterText(groupNameFieldFinder, '');
        await tester.pumpAndSettle();

        expect(find.byType(MetricsInactiveButton), findsOneWidget);
      },
    );

    testWidgets(
      "displays the loading text from the strategy if the widget is in the loading state",
      (WidgetTester tester) async {
        const loading = "loading";

        when(strategy.loadingText).thenReturn(loading);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        await tester.enterText(groupNameFieldFinder, testText);
        await tester.pump();

        await tester.tap(find.text(strategy.text));
        await tester.pump();
        await tester.idle();

        expect(find.text(loading), findsOneWidget);
      },
    );

    testWidgets(
      "calls the action of the given strategy on tap on the action button",
      (WidgetTester tester) async {
        const groupId = "id";
        const groupName = "name";
        final projectIds = UnmodifiableListView<String>(["id"]);

        final projectGroupDialogViewModel = ProjectGroupDialogViewModel(
          id: groupId,
          name: groupName,
          selectedProjectIds: projectIds,
        );

        final projectGroupsNotifier = ProjectGroupsNotifierMock();

        when(projectGroupsNotifier.projectGroupDialogViewModel)
            .thenReturn(projectGroupDialogViewModel);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        await tester.enterText(groupNameFieldFinder, testText);
        await tester.pump();

        await tester.tap(find.text(strategy.text));
        await tester.pump();

        verify(strategy.action(any, groupId, testText, projectIds))
            .called(equals(1));
      },
    );

    testWidgets(
      "does not call the action callback if the project group name is not valid",
      (WidgetTester tester) async {
        final projectGroupDialogViewModel = ProjectGroupDialogViewModel(
          selectedProjectIds: UnmodifiableListView<String>([]),
        );

        final projectGroupsNotifier = ProjectGroupsNotifierMock();

        when(projectGroupsNotifier.projectGroupDialogViewModel)
            .thenReturn(projectGroupDialogViewModel);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        await tester.tap(find.text(strategy.text));
        await tester.pump();

        verifyNever(strategy.action(any, any, any, any));
      },
    );

    testWidgets(
      "disables the action button if the action is in progress",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        await tester.enterText(groupNameFieldFinder, testText);
        await tester.pump();

        await tester.tap(find.text(strategy.text));
        await tester.pump();
        await tester.idle();

        final actionButton = tester.widget<RaisedButton>(find.widgetWithText(
          RaisedButton,
          strategy.loadingText,
        ));

        expect(actionButton.enabled, isFalse);
      },
    );

    testWidgets(
      "closes after the action completes successfully",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        await tester.enterText(groupNameFieldFinder, testText);
        await tester.pump();

        await tester.tap(find.text(strategy.text));
        await tester.pumpAndSettle();

        expect(find.byType(ProjectGroupDialog), findsNothing);
      },
    );

    testWidgets(
      "changes the state from the loading to not loading on action failed",
      (WidgetTester tester) async {
        when(projectGroupsNotifier.projectGroupSavingError).thenReturn("error");

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        await tester.tap(find.text(strategy.text));
        await tester.pump();

        expect(find.text(strategy.text), findsOneWidget);
      },
    );

    testWidgets(
      "displays the search icon as a prefix icon of the metrics text form field",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
          ));
        });

        final finder = find.byWidgetPredicate((widget) {
          if (widget is TextField && widget.decoration?.prefixIcon != null) {
            final iconFinder = find.descendant(
              of: find.byWidget(widget.decoration.prefixIcon),
              matching: find.byType(Image),
            );

            final image = tester.widget<Image>(iconFinder);

            final networkImage = image?.image as NetworkImage;
            final imageUrl = networkImage?.url;

            return imageUrl == 'icons/search.svg';
          }

          return false;
        });

        expect(finder, findsOneWidget);
      },
    );

    testWidgets(
      "searches for the projects on the search text field value changed",
      (tester) async {
        const searchText = "search";

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        await tester.enterText(searchFieldFinder, searchText);

        verify(projectGroupsNotifier.filterByProjectName(searchText))
            .called(equals(1));
      },
    );

    testWidgets(
      "displays a project group name in a group name text field",
      (tester) async {
        const name = "search";
        final projectGroupDialogViewModel = ProjectGroupDialogViewModel(
          name: name,
          selectedProjectIds: UnmodifiableListView<String>([]),
        );

        final projectGroupsNotifier = ProjectGroupsNotifierMock();

        when(projectGroupsNotifier.projectGroupDialogViewModel)
            .thenReturn(projectGroupDialogViewModel);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        final groupNameFinder = find.byWidgetPredicate(
          (widget) =>
              widget is MetricsTextFormField && widget.controller?.text == name,
        );

        expect(groupNameFinder, findsOneWidget);
      },
    );

    testWidgets(
      "applies the project group name validator to the project group name text field",
      (tester) async {
        final projectGroupDialogViewModel = ProjectGroupDialogViewModel(
          selectedProjectIds: UnmodifiableListView<String>([]),
        );

        final projectGroupsNotifier = ProjectGroupsNotifierMock();

        when(projectGroupsNotifier.projectGroupDialogViewModel)
            .thenReturn(projectGroupDialogViewModel);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        final projectGroupNameTextField = tester.widget<MetricsTextFormField>(
          find.widgetWithText(
            MetricsTextFormField,
            ProjectGroupsStrings.nameYourGroup,
          ),
        );

        expect(
          projectGroupNameTextField.validator,
          equals(ProjectGroupNameValidator.validate),
        );
      },
    );

    testWidgets(
      "displays the search for project text as a hint of the metrics text form field",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
          ));
        });

        final metricsTextFormField = find.byWidgetPredicate(
          (widget) =>
              widget is MetricsTextFormField &&
              widget.hint == CommonStrings.searchForProject,
        );

        expect(metricsTextFormField, findsOneWidget);
      },
    );

    testWidgets(
      "contains the project checkbox list",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _ProjectGroupDialogTestbed(strategy: strategy),
          );
        });

        expect(find.byType(ProjectCheckboxList), findsOneWidget);
      },
    );

    testWidgets(
      "displays a counter of the selected projects",
      (tester) async {
        final selectedProjectIds = ['1', '2'];
        final projectGroup = ProjectGroupDialogViewModel(
          selectedProjectIds: UnmodifiableListView(selectedProjectIds),
        );

        final notifier = ProjectGroupsNotifierMock();

        when(notifier.projectGroupDialogViewModel).thenReturn(projectGroup);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            projectGroupsNotifier: notifier,
            strategy: strategy,
          ));
        });

        final expectedCounterText = ProjectGroupsStrings.getSelectedCount(
          selectedProjectIds.length,
        );

        expect(find.text(expectedCounterText), findsOneWidget);
      },
    );

    testWidgets(
      "does not display a counter of the selected projects if no projects selected",
      (tester) async {
        final selectedProjectIds = <String>[];
        final projectGroup = ProjectGroupDialogViewModel(
          selectedProjectIds: UnmodifiableListView(selectedProjectIds),
        );

        final notifier = ProjectGroupsNotifierMock();

        when(notifier.projectGroupDialogViewModel).thenReturn(projectGroup);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            projectGroupsNotifier: notifier,
            strategy: strategy,
          ));
        });

        final expectedCounterText = ProjectGroupsStrings.getSelectedCount(
          selectedProjectIds.length,
        );

        expect(find.text(expectedCounterText), findsNothing);
      },
    );

    testWidgets(
      "does not call the action if the project group projects are not valid",
      (WidgetTester tester) async {
        final projects = List.generate(
          ProjectGroupProjects.maxNumberOfProjects + 1,
          (index) => index.toString(),
        );
        final projectGroupDialogViewModel = ProjectGroupDialogViewModel(
          selectedProjectIds: UnmodifiableListView<String>(projects),
          name: "some name",
        );

        when(projectGroupsNotifier.projectGroupDialogViewModel)
            .thenReturn(projectGroupDialogViewModel);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            projectGroupsNotifier: projectGroupsNotifier,
            strategy: strategy,
          ));
        });

        await tester.tap(find.byType(MetricsInactiveButton));

        verifyNever(strategy.action(any, any, any, any));
      },
    );

    testWidgets(
      "validates the project group projects on tap on the action button",
      (WidgetTester tester) async {
        final projects = List.generate(
          ProjectGroupProjects.maxNumberOfProjects + 1,
          (index) => index.toString(),
        );
        final projectGroupDialogViewModel = ProjectGroupDialogViewModel(
          selectedProjectIds: UnmodifiableListView<String>(projects),
          name: "some name",
        );

        when(projectGroupsNotifier.projectGroupDialogViewModel)
            .thenReturn(projectGroupDialogViewModel);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            projectGroupsNotifier: projectGroupsNotifier,
            strategy: strategy,
          ));
        });

        expect(
          find.text(ProjectGroupsStrings.getProjectsLimitExceeded(
            ProjectGroupProjects.maxNumberOfProjects,
          )),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      "applies the project group projects validator to the counter text with the value form field widget",
      (tester) async {
        final projectGroupDialogViewModel = ProjectGroupDialogViewModel(
          selectedProjectIds: UnmodifiableListView<String>([]),
        );

        final projectGroupsNotifier = ProjectGroupsNotifierMock();

        when(projectGroupsNotifier.projectGroupDialogViewModel)
            .thenReturn(projectGroupDialogViewModel);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        final formFieldFinder = find.byWidgetPredicate(
          (widget) => widget is ValueFormField<List<String>>,
        );
        final counterTextFormField =
            tester.widget<ValueFormField<List<String>>>(formFieldFinder);

        expect(
          counterTextFormField.validator,
          equals(ProjectGroupProjectsValidator.validate),
        );
      },
    );

    testWidgets(
      "displays the positive toast with the successful action message if an action finished successfully",
      (tester) async {
        when(projectGroupsNotifier.projectGroupDialogViewModel)
            .thenReturn(projectGroupDialogViewModel);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        await tester.enterText(groupNameFieldFinder, testText);
        await tester.pump();

        await tester.tap(find.text(strategy.text));
        await tester.pump();

        expect(
          find.widgetWithText(PositiveToast, toastMessage),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      "shows a negative toast with a project group saving error message if an action finished with en error",
      (tester) async {
        when(projectGroupsNotifier.projectGroupSavingError).thenReturn("error");

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        await tester.enterText(groupNameFieldFinder, testText);
        await tester.pump();

        await tester.tap(find.text(strategy.text));
        await tester.pump();

        expect(find.byType(NegativeToast), findsOneWidget);
      },
    );

    testWidgets(
      "displays the negative toast when there is a projects error message",
      (WidgetTester tester) async {
        const errorMessage = "Something went wrong";
        when(projectGroupsNotifier.projectsErrorMessage).thenReturn(
          errorMessage,
        );

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        await tester.pump();

        final negativeToastFinder = find.widgetWithText(
          NegativeToast,
          errorMessage,
        );

        expect(negativeToastFinder, findsOneWidget);
      },
    );

    testWidgets(
      "displays the negative toast with an projects error message if an error occurs",
      (WidgetTester tester) async {
        const errorMessage = "Something went wrong";

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        when(projectGroupsNotifier.projectsErrorMessage).thenReturn(
          errorMessage,
        );
        projectGroupsNotifier.notifyListeners();
        await tester.pumpAndSettle();

        final negativeToastFinder = find.widgetWithText(
          NegativeToast,
          errorMessage,
        );

        expect(negativeToastFinder, findsOneWidget);
      },
    );

    testWidgets(
      "closes normally after the view model's reset",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupDialogTestbed(
            strategy: strategy,
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        when(projectGroupsNotifier.projectGroupDialogViewModel)
            .thenReturn(null);

        await tester.enterText(groupNameFieldFinder, 'some text');

        await closeDialog(tester);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });
}

/// A testbed class required to test the [ProjectGroupDialog] widget.
///
/// Dismisses all shown [Toast]s on dispose.
class _ProjectGroupDialogTestbed extends StatefulWidget {
  /// A [ProjectGroupsNotifier] that will be injected and used in tests.
  final ProjectGroupsNotifier projectGroupsNotifier;

  /// A [ProjectGroupDialogStrategy] strategy applied to the [ProjectGroupDialog].
  final ProjectGroupDialogStrategy strategy;

  /// A [MetricsThemeData] used in tests.
  final MetricsThemeData theme;

  /// Creates a new instance of the [_ProjectGroupDialogTestbed]
  /// with the given [strategy], [projectGroupsNotifier] and [theme].
  ///
  /// The [theme] defaults to an empty [MetricsThemeData].
  const _ProjectGroupDialogTestbed({
    Key key,
    this.strategy,
    this.projectGroupsNotifier,
    this.theme = const MetricsThemeData(),
  }) : super(key: key);

  @override
  __ProjectGroupDialogTestbedState createState() =>
      __ProjectGroupDialogTestbedState();
}

class __ProjectGroupDialogTestbedState
    extends State<_ProjectGroupDialogTestbed> {
  @override
  Widget build(BuildContext context) {
    return TestInjectionContainer(
      projectGroupsNotifier: widget.projectGroupsNotifier,
      child: MetricsThemedTestbed(
        metricsThemeData: widget.theme,
        body: ProjectGroupDialog(
          strategy: widget.strategy,
        ),
      ),
    );
  }

  @override
  void dispose() {
    ToastManager().dismissAll();
    super.dispose();
  }
}

class ProjectGroupDialogStrategyMock extends Mock
    implements ProjectGroupDialogStrategy {}
