import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/update_prompt_storage.dart';
import '../../../../core/utils/app_info.dart';
import '../../domain/entities/app_version.dart';
import '../../domain/usecases/check_app_version.dart';

part 'app_update_state.dart';

/// Decides whether the parent is asked to update, told to, or left alone.
///
/// Every failure path ends in [UpdateRequirement.none]: an unreachable
/// backend, an unreadable version, a malformed response. A version check that
/// cannot be made must never be the reason someone cannot open the app — that
/// would turn one backend outage into an outage for every installed copy.
class AppUpdateCubit extends Cubit<AppUpdateState> {
  final CheckAppVersion checkAppVersion;
  final AppInfo appInfo;
  final UpdatePromptStorage promptStorage;

  AppUpdateCubit({
    required this.checkAppVersion,
    required this.appInfo,
    required this.promptStorage,
  }) : super(const AppUpdateState());

  /// Run at launch and again whenever the app comes back to the foreground —
  /// a parent who leaves the app open for a week would otherwise never be
  /// asked.
  Future<void> check() async {
    if (state.isChecking) return;
    emit(state.copyWith(isChecking: true));

    try {
      final current = await appInfo.version;
      final result = await checkAppVersion(
        CheckAppVersionParams(platform: appInfo.platform),
      );
      if (isClosed) return;

      result.fold(
        (_) => emit(state.copyWith(
          isChecking: false,
          requirement: UpdateRequirement.none,
        )),
        (version) => emit(state.copyWith(
          isChecking: false,
          currentVersion: current,
          version: version,
          requirement: _resolve(version, current),
        )),
      );
    } catch (_) {
      // `PackageInfo` failing is not something a parent can act on.
      if (isClosed) return;
      emit(state.copyWith(
        isChecking: false,
        requirement: UpdateRequirement.none,
      ));
    }
  }

  /// "Sonra" — only ever reachable on an optional update, and remembered per
  /// version so the same release is not offered twice.
  Future<void> postpone() async {
    final version = state.version;
    if (version == null || state.requirement != UpdateRequirement.recommended) {
      return;
    }

    await promptStorage.skip(version.latestVersion);
    if (isClosed) return;
    emit(state.copyWith(requirement: UpdateRequirement.none));
  }

  UpdateRequirement _resolve(AppVersion version, String current) {
    final requirement = version.requirementFor(current);
    // An offer already put off for this exact release stays put off; a forced
    // update ignores the record entirely.
    if (requirement == UpdateRequirement.recommended &&
        promptStorage.isSkipped(version.latestVersion)) {
      return UpdateRequirement.none;
    }
    return requirement;
  }
}
