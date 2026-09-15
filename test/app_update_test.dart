import 'dart:typed_data';

import 'package:bsbschool/core/error/failures.dart';
import 'package:bsbschool/core/l10n/l10n.dart';
import 'package:bsbschool/core/storage/update_prompt_storage.dart';
import 'package:bsbschool/core/utils/app_info.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/features/app_update/data/repositories/app_version_repository_impl.dart';
import 'package:bsbschool/features/app_update/data/services/app_version_service.dart';
import 'package:bsbschool/features/app_update/domain/entities/app_version.dart';
import 'package:bsbschool/features/app_update/domain/repositories/app_version_repository.dart';
import 'package:bsbschool/features/app_update/domain/usecases/check_app_version.dart';
import 'package:bsbschool/features/app_update/presentation/cubit/app_update_cubit.dart';
import 'package:bsbschool/features/app_update/presentation/widgets/update_gate.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the live endpoint answers, verbatim.
const _liveBody = '''
{"success":true,"platform":"ios","min_version":"2.0.7","latest_version":"2.0.7",
 "store_url":"https://apps.apple.com/us/app/british-school-in-baku/id1644665479",
 "message":null}
''';

class _RecordingAdapter implements HttpClientAdapter {
  final String body;
  final int statusCode;

  RequestOptions? request;

  _RecordingAdapter({required this.body, this.statusCode = 200});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

(AppVersionRepositoryImpl, _RecordingAdapter) _repository({
  String body = _liveBody,
  int statusCode = 200,
}) {
  final adapter = _RecordingAdapter(body: body, statusCode: statusCode);
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://online.bsb.edu.az/api/v1',
      validateStatus: (status) => status != null && status < 500,
    ),
  )..httpClientAdapter = adapter;
  return (AppVersionRepositoryImpl(service: AppVersionServiceImpl(dio)), adapter);
}

class _StubRepository implements AppVersionRepository {
  final AppVersion? version;
  final Failure? failure;

  const _StubRepository({this.version, this.failure});

  @override
  Future<Either<Failure, AppVersion>> fetch({required String platform}) async {
    return failure != null ? Left(failure!) : Right(version!);
  }
}

class _FakeAppInfo implements AppInfo {
  final String value;
  final bool throws;

  const _FakeAppInfo(this.value, {this.throws = false});

  @override
  Future<String> get version async {
    if (throws) throw Exception('no platform channel');
    return value;
  }

  @override
  String get platform => 'ios';
}

class _FakePromptStorage implements UpdatePromptStorage {
  String? skipped;

  _FakePromptStorage([this.skipped]);

  @override
  bool isSkipped(String version) => version.isNotEmpty && skipped == version;

  @override
  Future<void> skip(String version) async => skipped = version;
}

AppUpdateCubit _cubit({
  required String current,
  AppVersion? published,
  Failure? failure,
  _FakePromptStorage? storage,
  bool infoThrows = false,
}) {
  return AppUpdateCubit(
    checkAppVersion: CheckAppVersion(
      _StubRepository(version: published, failure: failure),
    ),
    appInfo: _FakeAppInfo(current, throws: infoThrows),
    promptStorage: storage ?? _FakePromptStorage(),
  );
}

const _published = AppVersion(
  minVersion: '2.0.7',
  latestVersion: '2.1.0',
  storeUrl: 'https://apps.apple.com/app/id1644665479',
);

void main() {
  group('comparing the installed build with the published one', () {
    UpdateRequirement requirement(String current,
        {String min = '2.0.7', String latest = '2.1.0'}) {
      return AppVersion(
        minVersion: min,
        latestVersion: latest,
        storeUrl: 'https://example.com',
      ).requirementFor(current);
    }

    test('below the minimum is blocked', () {
      expect(requirement('2.0.6'), UpdateRequirement.forced);
      expect(requirement('1.9.9'), UpdateRequirement.forced);
      expect(requirement('2.0'), UpdateRequirement.forced);
    });

    test('between the minimum and the latest is offered', () {
      expect(requirement('2.0.7'), UpdateRequirement.recommended);
      expect(requirement('2.0.99'), UpdateRequirement.recommended);
    });

    test('current or ahead is left alone', () {
      expect(requirement('2.1.0'), UpdateRequirement.none);
      expect(requirement('2.2.0'), UpdateRequirement.none);
      // A TestFlight build ahead of the store is not asked to downgrade.
      expect(requirement('3.0.0'), UpdateRequirement.none);
    });

    test('the parts are numbers, not text', () {
      // "2.0.10" sorts before "2.0.9" as a string; as a version it is newer.
      expect(requirement('2.0.10', min: '2.0.9', latest: '2.0.9'),
          UpdateRequirement.none);
      expect(requirement('2.0.9', min: '2.0.10', latest: '2.0.10'),
          UpdateRequirement.forced);
    });

    test("pubspec's build suffix does not count as a version part", () {
      expect(requirement('2.1.0+12'), UpdateRequirement.none);
      expect(requirement('2.0.6+99'), UpdateRequirement.forced);
    });

    test('an unreadable version on either side blocks nobody', () {
      // Fail-open: a half-configured backend or an unreadable bundle must not
      // turn into a wall every installed copy is stuck behind.
      expect(requirement(''), UpdateRequirement.none);
      expect(requirement('unknown'), UpdateRequirement.none);
      expect(requirement('2.0.6', min: '', latest: ''), UpdateRequirement.none);
      expect(requirement('2.0.6', min: 'n/a', latest: 'n/a'),
          UpdateRequirement.none);
    });
  });

  group('reading the endpoint', () {
    test('the live body is parsed as published', () async {
      final (repository, adapter) = _repository();

      final result = await repository.fetch(platform: 'ios');

      expect(adapter.request!.path, AppVersionServiceImpl.appVersionPath);
      expect(adapter.request!.queryParameters, {'platform': 'ios'});
      final version = result.getOrElse(() => throw StateError('no version'));
      expect(version.minVersion, '2.0.7');
      expect(version.latestVersion, '2.0.7');
      expect(version.storeUrl, contains('id1644665479'));
      expect(version.message, isNull);
    });

    test('a broken backend is a failure, not an exception', () async {
      final (repository, _) = _repository(body: 'gateway down', statusCode: 502);

      final result = await repository.fetch(platform: 'ios');

      expect(result.isLeft(), isTrue);
    });
  });

  group('what the app does with the answer', () {
    test('an older build is walled off', () async {
      final cubit = _cubit(current: '2.0.6', published: _published);
      addTearDown(cubit.close);

      await cubit.check();

      expect(cubit.state.requirement, UpdateRequirement.forced);
      expect(cubit.state.isBlocking, isTrue);
      expect(cubit.state.currentVersion, '2.0.6');
    });

    test('a supported build is offered the newer one', () async {
      final cubit = _cubit(current: '2.0.7', published: _published);
      addTearDown(cubit.close);

      await cubit.check();

      expect(cubit.state.requirement, UpdateRequirement.recommended);
      expect(cubit.state.isBlocking, isFalse);
    });

    test('"Sonra" is remembered for that release only', () async {
      final storage = _FakePromptStorage();
      final cubit = _cubit(
        current: '2.0.7',
        published: _published,
        storage: storage,
      );
      addTearDown(cubit.close);

      await cubit.check();
      await cubit.postpone();

      expect(cubit.state.requirement, UpdateRequirement.none);
      expect(storage.skipped, '2.1.0');

      // The next launch does not ask again for 2.1.0 …
      await cubit.check();
      expect(cubit.state.requirement, UpdateRequirement.none);
    });

    test('a later release is offered even after one was put off', () async {
      final storage = _FakePromptStorage('2.1.0');
      final cubit = _cubit(
        current: '2.0.7',
        published: const AppVersion(
          minVersion: '2.0.7',
          latestVersion: '2.2.0',
          storeUrl: 'https://example.com',
        ),
        storage: storage,
      );
      addTearDown(cubit.close);

      await cubit.check();

      expect(cubit.state.requirement, UpdateRequirement.recommended);
    });

    test('a forced update ignores what was put off', () async {
      final storage = _FakePromptStorage('2.1.0');
      final cubit = _cubit(
        current: '2.0.1',
        published: _published,
        storage: storage,
      );
      addTearDown(cubit.close);

      await cubit.check();

      expect(cubit.state.requirement, UpdateRequirement.forced);
    });

    test('an unreachable backend lets everyone in', () async {
      final cubit = _cubit(
        current: '1.0.0',
        failure: const NetworkFailure('yoxdur'),
      );
      addTearDown(cubit.close);

      await cubit.check();

      expect(cubit.state.requirement, UpdateRequirement.none);
      expect(cubit.state.isBlocking, isFalse);
    });

    test('an unreadable bundle version lets everyone in', () async {
      final cubit = _cubit(
        current: '2.0.1',
        published: _published,
        infoThrows: true,
      );
      addTearDown(cubit.close);

      await cubit.check();

      expect(cubit.state.isBlocking, isFalse);
    });
  });

  group('the gate on screen', () {
    Widget app(AppUpdateCubit cubit) {
      return MaterialApp(
        theme: DrTheme.dark,
        locale: const Locale('az'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: BlocProvider.value(
          value: cubit,
          child: const UpdateGate(child: Scaffold(body: Text('tətbiq'))),
        ),
      );
    }

    testWidgets('an unsupported build never reaches the app', (tester) async {
      final cubit = _cubit(current: '2.0.6', published: _published);
      addTearDown(cubit.close);

      await tester.pumpWidget(app(cubit));
      // Before the check answers, the app is what shows — no flash of a wall.
      expect(find.text('tətbiq'), findsOneWidget);

      await cubit.check();
      await tester.pump();

      expect(find.text('tətbiq'), findsNothing);
      expect(
        find.text(lookupAppL10n(const Locale('az')).updateForcedTitle),
        findsOneWidget,
      );
    });

    testWidgets('a supported build is not interrupted', (tester) async {
      final cubit = _cubit(
        current: '2.1.0',
        published: _published,
      );
      addTearDown(cubit.close);

      await tester.pumpWidget(app(cubit));
      await cubit.check();
      await tester.pump();

      expect(find.text('tətbiq'), findsOneWidget);
    });
  });
}
