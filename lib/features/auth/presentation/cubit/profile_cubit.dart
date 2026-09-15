import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/az_phone.dart';
import '../../domain/usecases/update_child_email.dart';
import '../../domain/usecases/update_password.dart';
import '../../domain/usecases/update_profile.dart';

part 'profile_state.dart';

/// Drives the three edit sheets on the profile tab: the parent's own details,
/// their password, and the login e-mail of one of their students.
///
/// Kept apart from `AuthBloc` so a save in flight never puts the whole session
/// into its loading state; the bloc is told to re-read the cached user once a
/// save lands, which is what moves the new values onto the screen.
class ProfileCubit extends Cubit<ProfileState> {
  final UpdateProfile updateProfile;
  final UpdateChildEmail updateChildEmail;
  final UpdatePassword updatePassword;

  /// Matches the backend's `new_password => min:6` rule.
  static const int minPasswordLength = 6;

  static final _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  ProfileCubit({
    required this.updateProfile,
    required this.updateChildEmail,
    required this.updatePassword,
  }) : super(const ProfileState());

  /// The parent's own row. [phone] is optional — an account registered before
  /// the backend stored one has nothing to show, and clearing it is allowed.
  Future<void> saveProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    if (state.isLoading) return;

    final trimmedName = name.trim();
    final trimmedEmail = email.trim();
    // The field is masked, so this only ever drops the spacing the mask put
    // there. An empty phone stays empty: it is optional.
    final canonicalPhone = AzPhone.e164(phone);

    final fieldErrors = <String, String>{};
    if (trimmedName.isEmpty) fieldErrors['name'] = L.s.profileNameRequired;
    if (trimmedEmail.isEmpty) {
      fieldErrors['email'] = L.s.forgotEmailRequired;
    } else if (!_emailRegExp.hasMatch(trimmedEmail)) {
      fieldErrors['email'] = L.s.forgotEmailInvalid;
    }
    if (!AzPhone.isEmpty(phone) && !AzPhone.isComplete(phone)) {
      // Masked input leaves one way to be wrong: stopping half way.
      fieldErrors['phone'] = L.s.registerPhoneInvalid;
    }
    if (fieldErrors.isNotEmpty) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        fieldErrors: fieldErrors,
      ));
      return;
    }

    emit(state.copyWith(status: ProfileStatus.loading));

    final result = await updateProfile(UpdateProfileParams(
      name: trimmedName,
      email: trimmedEmail,
      phone: canonicalPhone,
    ));
    if (isClosed) return;

    _settle(result.fold((failure) => failure, (_) => null), L.s.profileSaved);
  }

  /// The parent's own password, proved by the one they are signed in with.
  ///
  /// Nothing is stored locally — the session keeps running on the token it
  /// already has, so the parent stays where they are.
  Future<void> savePassword({
    required String currentPassword,
    required String newPassword,
    required String passwordConfirmation,
  }) async {
    if (state.isLoading) return;

    final fieldErrors = <String, String>{};
    if (currentPassword.isEmpty) {
      fieldErrors['current_password'] = L.s.profileCurrentPasswordRequired;
    }
    if (newPassword.isEmpty) {
      fieldErrors['new_password'] = L.s.forgotPasswordRequired;
    } else if (newPassword.length < minPasswordLength) {
      fieldErrors['new_password'] = L.s.forgotPasswordShort(minPasswordLength);
    } else if (newPassword != passwordConfirmation) {
      fieldErrors['new_password'] = L.s.forgotPasswordMismatch;
    }
    if (fieldErrors.isNotEmpty) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        fieldErrors: fieldErrors,
      ));
      return;
    }

    emit(state.copyWith(status: ProfileStatus.loading));

    final result = await updatePassword(UpdatePasswordParams(
      currentPassword: currentPassword,
      newPassword: newPassword,
    ));
    if (isClosed) return;

    _settle(
      result.fold((failure) => failure, (_) => null),
      L.s.profilePasswordSaved,
    );
  }

  /// One student's login address. The id comes from the roster the account was
  /// handed, so the sheet never has to ask for it.
  Future<void> saveChildEmail({
    required int childId,
    required String email,
  }) async {
    if (state.isLoading) return;

    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        fieldErrors: {'email': L.s.forgotEmailRequired},
      ));
      return;
    }
    if (!_emailRegExp.hasMatch(trimmedEmail)) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        fieldErrors: {'email': L.s.forgotEmailInvalid},
      ));
      return;
    }

    emit(state.copyWith(status: ProfileStatus.loading));

    final result = await updateChildEmail(
      UpdateChildEmailParams(childId: childId, email: trimmedEmail),
    );
    if (isClosed) return;

    _settle(
      result.fold((failure) => failure, (_) => null),
      L.s.profileChildEmailSaved,
    );
  }

  /// Drops the complaints as soon as an input is edited, so a corrected field
  /// stops shouting before it is submitted again.
  void inputChanged() {
    if (state.status != ProfileStatus.error) return;
    emit(state.copyWith(status: ProfileStatus.initial, fieldErrors: const {}));
  }

  /// One place for both saves to land: a [FieldValidationFailure] keeps its
  /// per-field map so each message goes back under its own input, anything
  /// else is a single line above the button.
  void _settle(Failure? failure, String successMessage) {
    if (failure == null) {
      emit(state.copyWith(
        status: ProfileStatus.success,
        message: successMessage,
      ));
      return;
    }

    emit(state.copyWith(
      status: ProfileStatus.error,
      message: failure.message,
      fieldErrors:
          failure is FieldValidationFailure ? failure.fieldErrors : const {},
    ));
  }
}
