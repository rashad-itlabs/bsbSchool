part of 'app_update_cubit.dart';

class AppUpdateState extends Equatable {
  /// What the app should do about the installed build.
  final UpdateRequirement requirement;

  /// What the backend published, once it has answered.
  final AppVersion? version;

  /// The version this binary reports — shown next to the store's.
  final String currentVersion;

  /// True while a check is in flight, so a resume during one does not start a
  /// second.
  final bool isChecking;

  const AppUpdateState({
    this.requirement = UpdateRequirement.none,
    this.version,
    this.currentVersion = '',
    this.isChecking = false,
  });

  bool get isBlocking => requirement == UpdateRequirement.forced;

  AppUpdateState copyWith({
    UpdateRequirement? requirement,
    AppVersion? version,
    String? currentVersion,
    bool? isChecking,
  }) =>
      AppUpdateState(
        requirement: requirement ?? this.requirement,
        version: version ?? this.version,
        currentVersion: currentVersion ?? this.currentVersion,
        isChecking: isChecking ?? this.isChecking,
      );

  @override
  List<Object?> get props => [requirement, version, currentVersion, isChecking];
}
