import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/usecases/delete_account.dart';

part 'delete_account_event.dart';
part 'delete_account_state.dart';

/// Drives the last step of "Hesabı sil": the password sheet.
///
/// Stops at [DeleteAccountStatus.deleted]; signing out is left to the screen,
/// which dispatches the usual logout to [AuthBloc] — one way out of a session,
/// whatever ended it.
class DeleteAccountBloc extends Bloc<DeleteAccountEvent, DeleteAccountState> {
  final DeleteAccount deleteAccount;

  DeleteAccountBloc({required this.deleteAccount})
      : super(const DeleteAccountState()) {
    on<DeleteAccountSubmitted>(_onSubmitted);
    on<DeleteAccountInputChanged>(_onInputChanged);
  }

  Future<void> _onSubmitted(
    DeleteAccountSubmitted event,
    Emitter<DeleteAccountState> emit,
  ) async {
    // One request at a time: the account can only go once.
    if (state.isSubmitting || state.status == DeleteAccountStatus.deleted) {
      return;
    }

    if (event.password.isEmpty) {
      emit(DeleteAccountState(
        status: DeleteAccountStatus.failure,
        passwordError: L.s.profileCurrentPasswordRequired,
      ));
      return;
    }

    emit(const DeleteAccountState(status: DeleteAccountStatus.submitting));

    final result = await deleteAccount(event.password);

    result.fold(
      (failure) {
        // The wrong-password case comes back per field; everything else is
        // about the request as a whole.
        final passwordError = failure is FieldValidationFailure
            ? failure.fieldErrors['password']
            : null;
        emit(DeleteAccountState(
          status: DeleteAccountStatus.failure,
          passwordError: passwordError,
          formError: passwordError == null ? failure.message : null,
        ));
      },
      (message) => emit(DeleteAccountState(
        status: DeleteAccountStatus.deleted,
        message: message,
      )),
    );
  }

  void _onInputChanged(
    DeleteAccountInputChanged event,
    Emitter<DeleteAccountState> emit,
  ) {
    if (state.status != DeleteAccountStatus.failure) return;
    emit(const DeleteAccountState());
  }
}
