import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/reset_password.dart';
import '../../../../core/l10n/l10n.dart';

part 'forgot_password_state.dart';

/// Drives the "Şifrənin bərpası" sheet. Kept apart from `AuthBloc` so a reset
/// in flight never puts the login button into its loading state.
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final ResetPassword resetPassword;

  /// Matches the backend's `new_password => min:6` rule.
  static const int minPasswordLength = 6;

  static final _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  ForgotPasswordCubit({required this.resetPassword})
      : super(const ForgotPasswordState());

  Future<void> submit({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final trimmedEmail = email.trim();

    final validationError = _validate(
      email: trimmedEmail,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    if (validationError != null) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.error,
        message: validationError,
      ));
      return;
    }

    emit(state.copyWith(status: ForgotPasswordStatus.loading));

    final result = await resetPassword(
      ResetPasswordParams(email: trimmedEmail, password: password),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: ForgotPasswordStatus.error,
        message: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: ForgotPasswordStatus.success,
        message: L.s.forgotDone,
      )),
    );
  }

  String? _validate({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) {
    if (email.isEmpty) return L.s.forgotEmailRequired;
    if (!_emailRegExp.hasMatch(email)) return L.s.forgotEmailInvalid;
    if (password.isEmpty) return L.s.forgotPasswordRequired;
    if (password.length < minPasswordLength) {
      return 'Şifrə ən azı $minPasswordLength simvol olmalıdır';
    }
    if (password != passwordConfirmation) return L.s.forgotPasswordMismatch;
    return null;
  }
}
