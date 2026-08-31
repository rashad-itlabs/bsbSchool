import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/usecases/register_parent.dart';

part 'register_event.dart';
part 'register_state.dart';

/// Drives the parent sign-up screen. Kept apart from [AuthBloc] on purpose: a
/// registration in flight must not put the login screen into its loading
/// state, and the account it creates is only signed in afterwards — by login,
/// the one place a token is minted.
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final RegisterParent registerParent;

  /// Matches the endpoint's `min:6` rule on `_passwordController`.
  static const int minPasswordLength = 6;

  /// Below this a "name" is a first name or a typo, not the "Ad Soyad" the
  /// school files the account under.
  static const int minNameLength = 5;

  static final _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Digits with the separators people actually type, optionally prefixed with
  /// `+`. Loose on purpose: a local `0501234567` and an international
  /// `+994 50 123 45 67` are both valid, and the backend has the final say.
  static final _phoneRegExp = RegExp(r'^\+?[\d\s()-]{9,20}$');

  /// Backend field name to the input it belongs to. `registerParent` validates
  /// on the form's controller names, so this map is literal rather than a
  /// translation of some snake_case scheme.
  static const Map<String, RegisterField> _serverFields = {
    '_name_nameController': RegisterField.name,
    '_emailController': RegisterField.email,
    '_phoneController': RegisterField.phone,
    '_passwordController': RegisterField.password,
    '_admissionController': RegisterField.admissionNo,
  };

  RegisterBloc({required this.registerParent})
      : super(const RegisterState()) {
    on<RegisterSubmitted>(_onSubmitted);
    on<RegisterFieldEdited>(_onFieldEdited);
  }

  /// Drops the message under the edited field, so a corrected input stops
  /// shouting before the form is submitted again.
  void _onFieldEdited(RegisterFieldEdited event, Emitter<RegisterState> emit) {
    if (!state.errors.containsKey(event.field)) return;
    final errors = Map<RegisterField, String>.from(state.errors)
      ..remove(event.field);
    emit(state.copyWith(status: RegisterStatus.initial, errors: errors));
  }

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    final name = event.name.trim();
    final email = event.email.trim();
    final phone = event.phone.trim();
    final admissionNo = event.admissionNo.trim();

    final errors = _validate(
      event,
      name: name,
      email: email,
      phone: phone,
      admissionNo: admissionNo,
    );
    if (errors.isNotEmpty) {
      emit(state.copyWith(status: RegisterStatus.error, errors: errors));
      return;
    }

    emit(state.copyWith(status: RegisterStatus.loading, errors: const {}));

    final result = await registerParent(RegisterParentParams(
      name: name,
      email: email,
      phone: phone,
      password: event.password,
      admissionNo: admissionNo,
      relation: event.relation,
    ));

    result.fold(
      (failure) => emit(_failureState(failure)),
      (_) => emit(state.copyWith(
        status: RegisterStatus.success,
        message: L.s.registerDone,
      )),
    );
  }

  /// Splits the backend's answer into lines that belong under an input and,
  /// for anything that maps to none, a single form-wide message.
  ///
  /// The endpoint gathers every problem into one `errors` basket — a duplicate
  /// e-mail and an unknown admission code arrive together — so the whole map
  /// is spread over the form at once rather than one message per attempt.
  RegisterState _failureState(Failure failure) {
    if (failure is! FieldValidationFailure || failure.fieldErrors.isEmpty) {
      return state.copyWith(
        status: RegisterStatus.error,
        message: failure.message,
      );
    }

    final errors = <RegisterField, String>{};
    final unmapped = <String>[];
    failure.fieldErrors.forEach((key, message) {
      final field = _serverFields[key];
      if (field != null) {
        errors[field] = message;
      } else {
        unmapped.add(message);
      }
    });

    return state.copyWith(
      status: RegisterStatus.error,
      errors: errors,
      // The mapped ones already sit under their own input; only a leftover
      // (an unknown key, a rejected `relation`) earns the banner.
      message: unmapped.isEmpty ? null : unmapped.join('\n'),
    );
  }

  /// Client-side rules, run before the request so an obviously incomplete form
  /// never costs a round trip. The backend re-checks all of them.
  Map<RegisterField, String> _validate(
    RegisterSubmitted event, {
    required String name,
    required String email,
    required String phone,
    required String admissionNo,
  }) {
    final errors = <RegisterField, String>{};

    if (name.isEmpty) {
      errors[RegisterField.name] = L.s.registerNameRequired;
    } else if (name.length < minNameLength || !name.contains(' ')) {
      errors[RegisterField.name] = L.s.registerNameShort;
    }

    if (email.isEmpty) {
      errors[RegisterField.email] = L.s.forgotEmailRequired;
    } else if (!_emailRegExp.hasMatch(email)) {
      errors[RegisterField.email] = L.s.forgotEmailInvalid;
    }

    if (phone.isEmpty) {
      errors[RegisterField.phone] = L.s.registerPhoneRequired;
    } else if (!_phoneRegExp.hasMatch(phone)) {
      errors[RegisterField.phone] = L.s.registerPhoneInvalid;
    }

    if (event.password.isEmpty) {
      errors[RegisterField.password] = L.s.registerPasswordRequired;
    } else if (event.password.length < minPasswordLength) {
      errors[RegisterField.password] =
          L.s.forgotPasswordShort(minPasswordLength);
    }

    // Only worth flagging once the password itself is usable, otherwise the
    // form shows two complaints about the same empty pair of fields.
    if (!errors.containsKey(RegisterField.password) &&
        event.password != event.passwordConfirmation) {
      errors[RegisterField.passwordConfirmation] = L.s.forgotPasswordMismatch;
    }

    if (admissionNo.isEmpty) {
      errors[RegisterField.admissionNo] = L.s.addChildEnterNumber;
    }

    if (!event.acceptedTerms) {
      errors[RegisterField.terms] = L.s.registerTermsRequired;
    }

    return errors;
  }
}
