import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ci_integration/client/buildkite/buildkite_client.dart';
import 'package:ci_integration/client/buildkite/models/buildkite_artifact.dart';
import 'package:ci_integration/client/buildkite/models/buildkite_artifacts_page.dart';
import 'package:ci_integration/client/buildkite/models/buildkite_build.dart';
import 'package:ci_integration/client/buildkite/models/buildkite_build_state.dart';
import 'package:ci_integration/client/buildkite/models/buildkite_builds_page.dart';
import 'package:ci_integration/source/buildkite/adapter/buildkite_source_client_adapter.dart';
import 'package:ci_integration/util/model/interaction_result.dart';
import 'package:metrics_core/metrics_core.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/extensions/interaction_result_answer.dart';
import '../test_utils/test_data/buildkite_test_data_generator.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("BuildkiteSourceClientAdapter", () {
    const pipelineSlug = "pipelineSlug";
    final testData = BuildkiteTestDataGenerator(
      pipelineSlug: pipelineSlug,
      coverage: Percent(0.5),
      webUrl: 'url',
      startedAt: DateTime(2020),
      finishedAt: DateTime(2021),
      duration: DateTime(2021).difference(DateTime(2020)),
    );

    final buildkiteClientMock = _BuildkiteClientMock();
    final adapter = BuildkiteSourceClientAdapter(
      buildkiteClient: buildkiteClientMock,
    );

    const coverageJson = <String, dynamic>{'pct': 0.5};
    final coverageBytes = utf8.encode(jsonEncode(coverageJson)) as Uint8List;

    PostExpectation<Future<InteractionResult<BuildkiteBuildsPage>>>
        whenFetchBuilds({BuildkiteArtifactsPage withArtifactsPage}) {
      when(
        buildkiteClientMock.downloadArtifact(any),
      ).thenSuccessWith(coverageBytes);

      when(buildkiteClientMock.fetchArtifacts(
        any,
        any,
        perPage: anyNamed('perPage'),
        page: anyNamed('page'),
      )).thenSuccessWith(withArtifactsPage);

      return when(
        buildkiteClientMock.fetchBuilds(
          any,
          state: anyNamed('state'),
          perPage: anyNamed('perPage'),
          page: anyNamed('page'),
        ),
      );
    }

    const defaultArtifactsPage = BuildkiteArtifactsPage(values: [
      BuildkiteArtifact(filename: "coverage-summary.json"),
    ]);
    final emptyArtifactsPage = BuildkiteArtifactsPage(
      page: 1,
      nextPageUrl: testData.webUrl,
      values: const [],
    );
    final defaultBuildsPage = BuildkiteBuildsPage(
      values: testData.generateBuildkiteBuildsByNumbers(
        buildNumbers: [2, 1],
      ),
    );
    final defaultBuildData = testData.generateBuildDataByNumbers(
      buildNumbers: [2, 1],
    );

    setUp(() {
      reset(buildkiteClientMock);
    });

    test("throws an ArgumentError if the given Buildkite client is null", () {
      expect(
        () => BuildkiteSourceClientAdapter(buildkiteClient: null),
        throwsArgumentError,
      );
    });

    test("creates an instance with the given parameters", () {
      final adapter = BuildkiteSourceClientAdapter(
        buildkiteClient: buildkiteClientMock,
      );

      expect(adapter.buildkiteClient, equals(buildkiteClientMock));
    });

    test(".fetchBuilds() fetches builds", () {
      whenFetchBuilds(
        withArtifactsPage: defaultArtifactsPage,
      ).thenSuccessWith(defaultBuildsPage);

      final result = adapter.fetchBuilds(pipelineSlug);

      expect(result, completion(equals(defaultBuildData)));
    });

    test(".fetchBuilds() fetches coverage for each build", () async {
      final expectedCoverage = [
        testData.coverage,
        testData.coverage,
      ];

      whenFetchBuilds(
        withArtifactsPage: defaultArtifactsPage,
      ).thenSuccessWith(defaultBuildsPage);

      final result = await adapter.fetchBuilds(pipelineSlug);
      final actualCoverage =
          result.map((buildData) => buildData.coverage).toList();

      expect(actualCoverage, equals(expectedCoverage));
    });

    test(
      ".fetchBuilds() maps the coverage value to null if the coverage summary artifact does not exist",
      () async {
        const expectedCoverage = [null, null];
        const artifactsPage = BuildkiteArtifactsPage(
          values: [BuildkiteArtifact(filename: 'test.json')],
        );

        whenFetchBuilds(
          withArtifactsPage: artifactsPage,
        ).thenSuccessWith(defaultBuildsPage);

        final result = await adapter.fetchBuilds(pipelineSlug);
        final actualCoverage =
            result.map((buildData) => buildData.coverage).toList();

        expect(actualCoverage, equals(expectedCoverage));
      },
    );

    test(
      ".fetchBuilds() maps the coverage value to null if an artifact bytes is null",
      () async {
        const expectedCoverage = [null, null];

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(defaultBuildsPage);

        when(buildkiteClientMock.downloadArtifact(any)).thenSuccessWith(null);

        final result = await adapter.fetchBuilds(pipelineSlug);
        final actualCoverage =
            result.map((buildData) => buildData.coverage).toList();

        expect(actualCoverage, equals(expectedCoverage));
      },
    );

    test(
      ".fetchBuilds() maps the coverage value to null if the JSON content parsing is failed",
      () async {
        const incorrectJson = "{pct : 100}";
        const expectedCoverage = [null, null];

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(defaultBuildsPage);

        when(buildkiteClientMock.downloadArtifact(any)).thenSuccessWith(
          utf8.encode(incorrectJson) as Uint8List,
        );

        final result = await adapter.fetchBuilds(pipelineSlug);
        final actualCoverage =
            result.map((buildData) => buildData.coverage).toList();

        expect(actualCoverage, equals(expectedCoverage));
      },
    );

    test(
      ".fetchBuilds() returns no more than the BuildkiteSourceClientAdapter.fetchLimit builds",
      () {
        final builds = testData.generateBuildkiteBuildsByNumbers(
          buildNumbers: List.generate(30, (index) => index),
        );
        final buildsPage = BuildkiteBuildsPage(values: builds);

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(buildsPage);

        final result = adapter.fetchBuilds(pipelineSlug);

        expect(
          result,
          completion(hasLength(BuildkiteSourceClientAdapter.fetchLimit)),
        );
      },
    );

    test(".fetchBuilds() skips blocked builds", () {
      final build = testData.generateBuildkiteBuild(blocked: true);
      final buildsPage = BuildkiteBuildsPage(values: [build]);

      whenFetchBuilds(
        withArtifactsPage: defaultArtifactsPage,
      ).thenSuccessWith(buildsPage);

      final result = adapter.fetchBuilds(pipelineSlug);

      expect(result, completion(isEmpty));
    });

    test(
      ".fetchBuilds() fetches builds using pagination for build artifacts",
      () {
        whenFetchBuilds(
          withArtifactsPage: emptyArtifactsPage,
        ).thenSuccessWith(defaultBuildsPage);

        when(buildkiteClientMock.fetchArtifactsNext(emptyArtifactsPage))
            .thenSuccessWith(defaultArtifactsPage);

        final result = adapter.fetchBuilds(pipelineSlug);

        expect(result, completion(equals(defaultBuildData)));
      },
    );

    test(
      ".fetchBuilds() fetches coverage for each build using pagination for build artifacts",
      () async {
        final expectedCoverage = [testData.coverage, testData.coverage];

        whenFetchBuilds(
          withArtifactsPage: emptyArtifactsPage,
        ).thenSuccessWith(defaultBuildsPage);

        when(buildkiteClientMock.fetchArtifactsNext(emptyArtifactsPage))
            .thenSuccessWith(defaultArtifactsPage);

        final result = await adapter.fetchBuilds(pipelineSlug);
        final actualCoverage =
            result.map((buildData) => buildData.coverage).toList();

        expect(actualCoverage, equals(expectedCoverage));
      },
    );

    test(
      ".fetchBuilds() fetches builds using pagination for builds",
      () async {
        final firstPage = BuildkiteBuildsPage(
          page: 1,
          nextPageUrl: testData.webUrl,
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [1],
          ),
        );
        final secondPage = BuildkiteBuildsPage(
          page: 2,
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [2],
          ),
        );
        final expected = testData.generateBuildDataByNumbers(
          buildNumbers: [1, 2],
        );

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(firstPage);

        when(buildkiteClientMock.fetchBuildsNext(firstPage))
            .thenSuccessWith(secondPage);

        final result = adapter.fetchBuilds(pipelineSlug);

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchBuilds() throws a StateError if fetching a builds page fails",
      () {
        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenErrorWith();

        final result = adapter.fetchBuilds(pipelineSlug);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchBuilds() throws a StateError if paginating through builds fails",
      () {
        final firstPage = BuildkiteBuildsPage(
          nextPageUrl: testData.webUrl,
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [1],
          ),
        );

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(firstPage);

        when(buildkiteClientMock.fetchBuildsNext(firstPage)).thenErrorWith();

        final result = adapter.fetchBuilds(pipelineSlug);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchBuilds() throws a StateError if fetching the coverage artifact fails",
      () {
        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(defaultBuildsPage);

        when(buildkiteClientMock.fetchArtifacts(
          any,
          any,
          perPage: anyNamed('perPage'),
          page: anyNamed('page'),
        )).thenErrorWith();

        final result = adapter.fetchBuilds(pipelineSlug);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchBuilds() throws a StateError if paginating through coverage artifacts fails",
      () {
        whenFetchBuilds(
          withArtifactsPage: emptyArtifactsPage,
        ).thenSuccessWith(defaultBuildsPage);

        when(buildkiteClientMock.fetchArtifactsNext(emptyArtifactsPage))
            .thenErrorWith();

        final result = adapter.fetchBuilds(pipelineSlug);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchBuilds() throws a StateError if downloading a coverage artifact fails",
      () {
        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(defaultBuildsPage);

        when(buildkiteClientMock.downloadArtifact(any)).thenErrorWith();

        final result = adapter.fetchBuilds(pipelineSlug);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchBuilds() maps fetched builds states according to the specification",
      () {
        const states = [
          BuildkiteBuildState.passed,
          BuildkiteBuildState.failed,
          BuildkiteBuildState.canceled,
          BuildkiteBuildState.notRun,
          BuildkiteBuildState.scheduled,
          BuildkiteBuildState.blocked,
          BuildkiteBuildState.notRun,
          BuildkiteBuildState.finished,
          BuildkiteBuildState.running,
          BuildkiteBuildState.skipped,
          null,
        ];

        const expectedStates = [
          BuildStatus.successful,
          BuildStatus.failed,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
        ];

        final expectedBuilds = testData.generateBuildDataByStates(
          states: expectedStates,
        );

        final builds = testData.generateBuildkiteBuildsByStates(
          states: states,
        );

        whenFetchBuilds(withArtifactsPage: defaultArtifactsPage)
            .thenSuccessWith(BuildkiteBuildsPage(values: builds));

        final result = adapter.fetchBuilds(pipelineSlug);

        expect(result, completion(equals(expectedBuilds)));
      },
    );

    test(
      ".fetchBuilds() maps fetched builds' difference between the startedAt and finishedAt dates to the duration",
      () async {
        final build = testData.generateBuildkiteBuild();
        final start = build.startedAt;
        final finish = build.finishedAt;
        final expectedDuration = finish.difference(start);

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuilds(pipelineSlug);
        final duration = result.first.duration;

        expect(duration, equals(expectedDuration));
      },
    );

    test(
      ".fetchBuilds() maps fetched builds' difference between the startedAt and finishedAt dates to the Duration.zero if the startedAt date is null",
      () async {
        final build = BuildkiteBuild(
          blocked: false,
          startedAt: null,
          finishedAt: DateTime.now(),
        );

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuilds(pipelineSlug);
        final duration = result.first.duration;

        expect(duration, equals(Duration.zero));
      },
    );

    test(
      ".fetchBuilds() maps fetched builds' difference between the startedAt and finishedAt dates to the Duration.zero if the finishedAt date is null",
      () async {
        final build = BuildkiteBuild(
          blocked: false,
          startedAt: DateTime.now(),
          finishedAt: null,
        );

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuilds(pipelineSlug);
        final duration = result.first.duration;

        expect(duration, equals(Duration.zero));
      },
    );

    test(
      ".fetchBuilds() maps fetched builds' url to the empty string if the url is null",
      () async {
        const build = BuildkiteBuild(
          blocked: false,
          webUrl: null,
        );

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(const BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuilds(pipelineSlug);
        final url = result.first.url;

        expect(url, equals(''));
      },
    );

    test(
      ".fetchBuilds() maps fetched builds' startedAt date to the finishedAt date if the startedAt date is null",
      () async {
        final finishedAt = DateTime.now();
        final build = BuildkiteBuild(
          blocked: false,
          startedAt: null,
          finishedAt: finishedAt,
        );

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuilds(pipelineSlug);
        final startedAt = result.first.startedAt;

        expect(startedAt, equals(finishedAt));
      },
    );

    test(
      ".fetchBuilds() maps fetched builds' startedAt date to the DateTime.now() date if the startedAt and finishedAt dates are null",
      () async {
        const build = BuildkiteBuild(
          blocked: false,
          startedAt: null,
          finishedAt: null,
        );

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(const BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuilds(pipelineSlug);
        final startedAt = result.first.startedAt;

        expect(startedAt, isNotNull);
      },
    );

    test(
      ".fetchBuildsAfter() throws an ArgumentError if the build is null",
      () {
        final result = adapter.fetchBuildsAfter(pipelineSlug, null);

        expect(result, throwsArgumentError);
      },
    );

    test(
      ".fetchBuildsAfter() fetches all builds after the given one",
      () {
        final lastBuild = testData.generateBuildData(buildNumber: 1);
        final buildsPage = BuildkiteBuildsPage(
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [4, 3, 2, 1],
          ),
        );
        final expected = testData.generateBuildDataByNumbers(
          buildNumbers: [4, 3, 2],
        );

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(buildsPage);

        final result = adapter.fetchBuildsAfter(pipelineSlug, lastBuild);

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchBuildsAfter() fetches builds with a greater build number than the given if the given number is not found",
      () {
        final lastBuild = testData.generateBuildData(buildNumber: 4);
        final buildsPage = BuildkiteBuildsPage(
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [7, 6, 5, 3, 2, 1],
          ),
        );
        final expected = testData.generateBuildDataByNumbers(
          buildNumbers: [7, 6, 5],
        );

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(buildsPage);

        final result = adapter.fetchBuildsAfter(pipelineSlug, lastBuild);

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchBuildsAfter() returns an empty list if there are no new builds",
      () {
        final lastBuild = testData.generateBuildData(buildNumber: 4);
        final buildsPage = BuildkiteBuildsPage(
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [4, 3, 2, 1],
          ),
        );

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(buildsPage);

        final result = adapter.fetchBuildsAfter(pipelineSlug, lastBuild);

        expect(result, completion(isEmpty));
      },
    );

    test(
      ".fetchBuildsAfter() fetches coverage for each build",
      () async {
        final expected = [
          testData.coverage,
          testData.coverage,
          testData.coverage,
        ];
        final lastBuild = testData.generateBuildData(buildNumber: 1);
        final buildsPage = BuildkiteBuildsPage(
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [4, 3, 2, 1],
          ),
        );

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(buildsPage);

        final result = await adapter.fetchBuildsAfter(pipelineSlug, lastBuild);
        final coverage = result.map((build) => build.coverage).toList();

        expect(coverage, equals(expected));
      },
    );

    test(
      ".fetchBuildsAfter() maps the coverage value to null if the coverage summary artifact does not exist",
      () async {
        const expectedCoverage = [null, null, null];
        const artifactsPage = BuildkiteArtifactsPage(
          values: [BuildkiteArtifact(filename: "test.json")],
        );
        final lastBuild = testData.generateBuildData(buildNumber: 1);

        final buildsPage = BuildkiteBuildsPage(
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [4, 3, 2, 1],
          ),
        );

        whenFetchBuilds(
          withArtifactsPage: artifactsPage,
        ).thenSuccessWith(buildsPage);

        final result = await adapter.fetchBuildsAfter(pipelineSlug, lastBuild);
        final coverage = result.map((build) => build.coverage).toList();

        expect(coverage, equals(expectedCoverage));
      },
    );

    test(
      ".fetchBuildsAfter() maps the coverage value to null if an artifact bytes is null",
      () async {
        const expectedCoverage = [null, null];
        final lastBuild = testData.generateBuildData(buildNumber: 1);
        final buildsPage = BuildkiteBuildsPage(
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [3, 2, 1],
          ),
        );

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(buildsPage);

        when(buildkiteClientMock.downloadArtifact(any)).thenSuccessWith(null);

        final result = await adapter.fetchBuildsAfter(pipelineSlug, lastBuild);
        final actualCoverage =
            result.map((buildData) => buildData.coverage).toList();

        expect(actualCoverage, equals(expectedCoverage));
      },
    );

    test(
      ".fetchBuildsAfter() maps the coverage value to null if the JSON content parsing is failed",
      () async {
        const expectedCoverage = [null, null];
        const incorrectJson = "{pct : 100}";
        final lastBuild = testData.generateBuildData(buildNumber: 1);
        final buildsPage = BuildkiteBuildsPage(
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [3, 2, 1],
          ),
        );

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(buildsPage);

        when(buildkiteClientMock.downloadArtifact(any)).thenSuccessWith(
          utf8.encode(incorrectJson) as Uint8List,
        );

        final result = await adapter.fetchBuildsAfter(pipelineSlug, lastBuild);
        final actualCoverage =
            result.map((buildData) => buildData.coverage).toList();

        expect(actualCoverage, equals(expectedCoverage));
      },
    );

    test(
      ".fetchBuildsAfter() fetches coverage for each build using pagination for build artifacts",
      () async {
        final lastBuild = testData.generateBuildData(buildNumber: 1);
        final buildsPage = BuildkiteBuildsPage(
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [4, 3, 2, 1],
          ),
        );
        final expectedCoverage = [
          testData.coverage,
          testData.coverage,
          testData.coverage,
        ];

        whenFetchBuilds(
          withArtifactsPage: emptyArtifactsPage,
        ).thenSuccessWith(buildsPage);

        when(buildkiteClientMock.fetchArtifactsNext(emptyArtifactsPage))
            .thenSuccessWith(defaultArtifactsPage);

        final result = await adapter.fetchBuildsAfter(pipelineSlug, lastBuild);
        final coverage = result.map((build) => build.coverage).toList();

        expect(coverage, equals(expectedCoverage));
      },
    );

    test(
      ".fetchBuildsAfter() skips the blocked builds",
      () {
        final build = testData.generateBuildkiteBuild(number: 2, blocked: true);
        final buildsPage = BuildkiteBuildsPage(values: [build]);
        final lastBuild = testData.generateBuildData(buildNumber: 1);

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(buildsPage);

        final result = adapter.fetchBuildsAfter(pipelineSlug, lastBuild);

        expect(result, completion(isEmpty));
      },
    );

    test(
      ".fetchBuildsAfter() fetches builds using pagination for buildkite builds",
      () {
        final firstBuild = testData.generateBuildData(buildNumber: 1);
        final expected = testData.generateBuildDataByNumbers(
          buildNumbers: [4, 3, 2],
        );
        final firstPage = BuildkiteBuildsPage(
          page: 1,
          nextPageUrl: testData.webUrl,
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [4, 3],
          ),
        );
        final secondPage = BuildkiteBuildsPage(
          page: 2,
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [2, 1],
          ),
        );

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(firstPage);

        when(buildkiteClientMock.fetchBuildsNext(firstPage))
            .thenSuccessWith(secondPage);

        final result = adapter.fetchBuildsAfter(pipelineSlug, firstBuild);

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchBuildsAfter() fetches builds using the pagination for buildkite artifacts",
      () {
        final lastBuild = testData.generateBuildData(buildNumber: 1);
        final buildsPage = BuildkiteBuildsPage(
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [4, 3, 2, 1],
          ),
        );
        final expected = testData.generateBuildDataByNumbers(
          buildNumbers: [4, 3, 2],
        );

        whenFetchBuilds(
          withArtifactsPage: emptyArtifactsPage,
        ).thenSuccessWith(buildsPage);

        when(buildkiteClientMock.fetchArtifactsNext(emptyArtifactsPage))
            .thenSuccessWith(defaultArtifactsPage);

        final result = adapter.fetchBuildsAfter(pipelineSlug, lastBuild);

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchBuildsAfter() throws a StateError if fetching a builds page fails",
      () {
        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(defaultBuildsPage);

        when(buildkiteClientMock.fetchBuilds(
          any,
          state: anyNamed('state'),
          perPage: anyNamed('perPage'),
          page: anyNamed('page'),
        )).thenErrorWith();

        final lastBuild = testData.generateBuildData(buildNumber: 1);

        final result = adapter.fetchBuildsAfter(pipelineSlug, lastBuild);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchBuildsAfter() throws a StateError if paginating through Buildkite builds fails",
      () {
        final lastBuild = testData.generateBuildData(buildNumber: 1);
        final firstPage = BuildkiteBuildsPage(
          nextPageUrl: testData.webUrl,
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [4, 3],
          ),
        );

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(firstPage);

        when(buildkiteClientMock.fetchBuildsNext(firstPage)).thenErrorWith();

        final result = adapter.fetchBuildsAfter(pipelineSlug, lastBuild);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchBuildsAfter() throws a StateError if fetching the coverage artifact fails",
      () {
        whenFetchBuilds().thenSuccessWith(defaultBuildsPage);

        when(buildkiteClientMock.fetchArtifacts(
          any,
          any,
          perPage: anyNamed('perPage'),
          page: anyNamed('page'),
        )).thenErrorWith();

        final lastBuild = testData.generateBuildData(buildNumber: 1);

        final result = adapter.fetchBuildsAfter(pipelineSlug, lastBuild);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchBuildsAfter() throws a StateError if paginating through builds artifacts fails",
      () {
        whenFetchBuilds(
          withArtifactsPage: emptyArtifactsPage,
        ).thenSuccessWith(defaultBuildsPage);

        when(buildkiteClientMock.fetchArtifactsNext(emptyArtifactsPage))
            .thenErrorWith();

        final lastBuild = testData.generateBuildData(buildNumber: 1);

        final result = adapter.fetchBuildsAfter(pipelineSlug, lastBuild);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchBuildsAfter() throws a StateError if downloading an artifact fails",
      () {
        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(defaultBuildsPage);

        when(buildkiteClientMock.downloadArtifact(any)).thenErrorWith();

        final lastBuild = testData.generateBuildData(buildNumber: 1);

        final result = adapter.fetchBuildsAfter(pipelineSlug, lastBuild);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched builds states according to the specification",
      () {
        const states = [
          BuildkiteBuildState.passed,
          BuildkiteBuildState.failed,
          BuildkiteBuildState.canceled,
          BuildkiteBuildState.notRun,
          BuildkiteBuildState.scheduled,
          BuildkiteBuildState.blocked,
          BuildkiteBuildState.notRun,
          BuildkiteBuildState.finished,
          BuildkiteBuildState.running,
          BuildkiteBuildState.skipped,
          null,
        ];

        const expectedStates = [
          BuildStatus.successful,
          BuildStatus.failed,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
        ];

        final expectedBuilds = testData.generateBuildDataByStates(
          states: expectedStates,
        );

        final builds = testData.generateBuildkiteBuildsByStates(
          states: states,
        );
        final lastBuild = testData.generateBuildData(buildNumber: 0);

        whenFetchBuilds(withArtifactsPage: defaultArtifactsPage)
            .thenSuccessWith(BuildkiteBuildsPage(values: builds));

        final result = adapter.fetchBuildsAfter(pipelineSlug, lastBuild);

        expect(result, completion(equals(expectedBuilds)));
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched builds' difference between the startedAt and finishedAt dates to the duration",
      () async {
        final firstBuild = testData.generateBuildData(buildNumber: 1);
        final build = testData.generateBuildkiteBuild(number: 2);
        final start = build.startedAt;
        final finish = build.finishedAt;
        final expectedDuration = finish.difference(start);

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuildsAfter(pipelineSlug, firstBuild);
        final duration = result.first.duration;

        expect(duration, equals(expectedDuration));
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched builds' difference between the startedAt and finishedAt dates to the Duration.zero if the startedAt date is null",
      () async {
        final build = BuildkiteBuild(
          number: 2,
          blocked: false,
          startedAt: null,
          finishedAt: DateTime.now(),
        );
        final firstBuild = testData.generateBuildData(buildNumber: 1);

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuildsAfter(pipelineSlug, firstBuild);
        final duration = result.first.duration;

        expect(duration, equals(Duration.zero));
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched builds' difference between the startedAt and finishedAt dates to the Duration.zero if the finishedAt date is null",
      () async {
        final build = BuildkiteBuild(
          number: 2,
          blocked: false,
          startedAt: DateTime.now(),
          finishedAt: null,
        );
        final firstBuild = testData.generateBuildData(buildNumber: 1);

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuildsAfter(pipelineSlug, firstBuild);
        final duration = result.first.duration;

        expect(duration, equals(Duration.zero));
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched builds' startedAt date to the DateTime.now() date if the startedAt and finishedAt dates are null",
      () async {
        const build = BuildkiteBuild(
          number: 2,
          blocked: false,
          startedAt: null,
          finishedAt: null,
        );
        final firstBuild = testData.generateBuildData(buildNumber: 1);

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(const BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuildsAfter(pipelineSlug, firstBuild);
        final startedAt = result.first.startedAt;

        expect(startedAt, isNotNull);
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched builds' difference between the startedAt and finishedAt dates to the Duration.zero if the finishedAt date is null",
      () async {
        final build = BuildkiteBuild(
          number: 2,
          blocked: false,
          startedAt: DateTime.now(),
          finishedAt: null,
        );
        final firstBuild = testData.generateBuildData(buildNumber: 1);

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuildsAfter(pipelineSlug, firstBuild);
        final duration = result.first.duration;

        expect(duration, equals(Duration.zero));
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched builds' url to the empty string if the url is null",
      () async {
        const build = BuildkiteBuild(
          number: 2,
          blocked: false,
          webUrl: null,
        );
        final firstBuild = testData.generateBuildData(buildNumber: 1);

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(const BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuildsAfter(pipelineSlug, firstBuild);
        final url = result.first.url;

        expect(url, equals(''));
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched builds' startedAt date to the finishedAt date if the startedAt date is null",
      () async {
        final finishedAt = DateTime.now();
        final build = BuildkiteBuild(
          number: 2,
          blocked: false,
          startedAt: null,
          finishedAt: finishedAt,
        );
        final firstBuild = testData.generateBuildData(buildNumber: 1);

        whenFetchBuilds(
          withArtifactsPage: defaultArtifactsPage,
        ).thenSuccessWith(BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuildsAfter(pipelineSlug, firstBuild);
        final startedAt = result.first.startedAt;

        expect(startedAt, equals(finishedAt));
      },
    );

    test(".dispose() closes the Buildkite client", () {
      adapter.dispose();

      verify(buildkiteClientMock.close()).called(1);
    });
  });
}

class _BuildkiteClientMock extends Mock implements BuildkiteClient {}
