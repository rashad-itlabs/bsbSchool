import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/az_phone.dart';
import '../../domain/usecases/send_email_change_otp.dart';
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
///
/// A login e-mail never changes on the first press. A new address gets a
/// 6-digit code mailed to it, and the save goes out only with that code —
/// the backend writes nothing until the code checks out, so a mistyped
/// address can't become the one the account signs in with.
class ProfileCubit extends Cubit<ProfileState> {
  final UpdateProfile updateProfile;
  final UpdateChildEmail updateChildEmail;
  final UpdatePassword updatePassword;
  final SendEmailChangeOtp sendEmailChangeOtp;

  /// Matches the backend's `new_password => min:6` rule.
  static const int minPasswordLength = 6;

  /// Matches the length of the code the backend generates.
  static const int codeLength = 6;

  static final _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Timer? _cooldownTimer;

  /// The save the code step is holding back, exactly as it was submitted.
  _PendingSave? _pending;

  ProfileCubit({
    required this.updateProfile,
    required this.updateChildEmail,
    required this.updatePassword,
    required this.sendEmailChangeOtp,
  }) : super(const ProfileState());

  /// The parent's own row. [phone] is optional — an account registered before
  /// the backend stored one has nothing to show, and clearing it is allowed.
  ///
  /// [currentEmail] is the address the account signs in with now: when
  /// [email] differs from it, a code is mailed first and the save waits for
  /// [confirmCode].
  Future<void> saveProfile({
    required String name,
    required String email,
    required String phone,
    required String currentEmail,
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

    if (!_isSameAddress(trimmedEmail, currentEmail)) {
      _pending = _PendingSave(
        email: trimmedEmail,
        name: trimmedName,
        phone: canonicalPhone,
      );
      return _requestCode();
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
  ///
  /// Same rule as [saveProfile]: a new address is confirmed by the code
  /// mailed to it before anything is saved.
  Future<void> saveChildEmail({
    required int childId,
    required String email,
    required String currentEmail,
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

    // Saving the address the student already has changes nothing, so there
    // is nothing to confirm either.
    if (_isSameAddress(trimmedEmail, currentEmail)) {
      emit(state.copyWith(
        status: ProfileStatus.success,
        message: L.s.profileChildEmailSaved,
      ));
      return;
    }

    _pending = _PendingSave(email: trimmedEmail, childId: childId);
    return _requestCode();
  }

  /// The code step — sends the held-back save together with [code]. A wrong
  /// code keeps the sheet on this step, with nothing saved.
  Future<void> confirmCode(String code) async {
    final pending = _pending;
    if (pending == null || state.isLoading) return;

    final otp = code.trim();
    if (otp.isEmpty || otp.length != codeLength) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        fieldErrors: {
          'otp': otp.isEmpty ? L.s.otpRequired : L.s.otpIncomplete(codeLength),
        },
      ));
      return;
    }

    emit(state.copyWith(status: ProfileStatus.loading));

    final childId = pending.childId;
    final result = childId == null
        ? await updateProfile(UpdateProfileParams(
            name: pending.name!,
            email: pending.email,
            phone: pending.phone!,
            otp: otp,
          ))
        : await updateChildEmail(UpdateChildEmailParams(
            childId: childId,
            email: pending.email,
            otp: otp,
          ));
    if (isClosed) return;

    final failure = result.fold((failure) => failure, (_) => null);
    if (failure == null) _cooldownTimer?.cancel();
    _settle(
      failure,
      childId == null ? L.s.profileSaved : L.s.profileChildEmailSaved,
    );
  }

  /// Mails a fresh code when the first one never arrived; the previous one
  /// stops working.
  Future<void> resendCode() async {
    final pending = _pending;
    if (pending == null || !state.canResend) return;

    emit(state.copyWith(isResending: true));

    final result = await sendEmailChangeOtp(SendEmailChangeOtpParams(
      email: pending.email,
      childId: pending.childId,
    ));
    if (isClosed) return;

    result.fold(
      // No new mail went out, so the link stays available for another try.
      (failure) => emit(state.copyWith(
        isResending: false,
        status: ProfileStatus.error,
        message: failure.message,
        fieldErrors:
            failure is FieldValidationFailure ? failure.fieldErrors : const {},
      )),
      (seconds) {
        emit(state.copyWith(
          isResending: false,
          status: ProfileStatus.initial,
          message: L.s.otpResent,
          resendSeconds: seconds,
        ));
        _tickCooldown();
      },
    );
  }

  /// Back to the form — the code went to a mistyped address, so it is fixed
  /// there rather than waited on. Nothing was saved, so nothing is undone.
  void backToForm() {
    if (state.isLoading) return;
    _cooldownTimer?.cancel();
    _pending = null;
    emit(const ProfileState());
  }

  /// Mails the code for [_pending] and moves the sheet to the code step. A
  /// refusal (address taken, unchanged, malformed) stays on the form, under
  /// the e-mail field.
  Future<void> _requestCode() async {
    final pending = _pending!;
    emit(state.copyWith(status: ProfileStatus.loading));

    final result = await sendEmailChangeOtp(SendEmailChangeOtpParams(
      email: pending.email,
      childId: pending.childId,
    ));
    if (isClosed) return;

    result.fold(
      (failure) {
        _pending = null;
        _fail(failure);
      },
      (seconds) {
        emit(state.copyWith(
          status: ProfileStatus.otpSent,
          pendingEmail: pending.email,
          resendSeconds: seconds,
        ));
        _tickCooldown();
      },
    );
  }

  /// The backend compares addresses without regard to case (so does MySQL),
  /// so a change of case alone is not a new address and needs no code.
  static bool _isSameAddress(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  /// Counts [ProfileState.resendSeconds] down to zero, one second at a time.
  void _tickCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }
      final remaining = state.resendSeconds - 1;
      if (remaining <= 0) timer.cancel();
      // `copyWith` drops the message and field errors unless they are handed
      // back, and this fires every second while the code is being typed —
      // without carrying them a rejected code's error would vanish a tick
      // later.
      emit(state.copyWith(
        resendSeconds: remaining < 0 ? 0 : remaining,
        message: state.message,
        fieldErrors: state.fieldErrors,
      ));
    });
  }

  @override
  Future<void> close() {
    _cooldownTimer?.cancel();
    return super.close();
  }

  /// Drops the complaints as soon as an input is edited, so a corrected field
  /// stops shouting before it is submitted again. The code step, if open,
  /// stays open.
  void inputChanged() {
    if (state.status != ProfileStatus.error) return;
    emit(state.copyWith(status: ProfileStatus.initial, fieldErrors: const {}));
  }

  /// One place for both saves to land.
  void _settle(Failure? failure, String successMessage) {
    if (failure == null) {
      emit(state.copyWith(
        status: ProfileStatus.success,
        message: successMessage,
      ));
      return;
    }
    _fail(failure);
  }

  /// A [FieldValidationFailure] keeps its per-field map so each message goes
  /// back under its own input, anything else is a single line above the
  /// button.
  void _fail(Failure failure) {
    emit(state.copyWith(
      status: ProfileStatus.error,
      message: failure.message,
      fieldErrors:
          failure is FieldValidationFailure ? failure.fieldErrors : const {},
    ));
  }
}

/// What the code step will send once the code is in. [childId] set means one
/// student's address; otherwise the account's own row, [name] and [phone]
/// included — the backend saves the whole form together or not at all.
class _PendingSave {
  final String email;
  final int? childId;
  final String? name;
  final String? phone;

  const _PendingSave({
    required this.email,
    this.childId,
    this.name,
    this.phone,
  });
}
