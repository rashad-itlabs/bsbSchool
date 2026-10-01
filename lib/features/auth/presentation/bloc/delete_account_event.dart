part of 'delete_account_bloc.dart';

abstract class DeleteAccountEvent extends Equatable {
  const DeleteAccountEvent();

  @override
  List<Object?> get props => [];
}

/// The parent confirmed with their password.
class DeleteAccountSubmitted extends DeleteAccountEvent {
  final String password;

  const DeleteAccountSubmitted(this.password);

  // Kept out of props so the password never shows up in a printed event.
  @override
  List<Object?> get props => [];
}

/// The password field was edited — clears the complaint under it.
class DeleteAccountInputChanged extends DeleteAccountEvent {
  const DeleteAccountInputChanged();
}
