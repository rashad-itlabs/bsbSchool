import 'package:equatable/equatable.dart';

/// One student on the account, as `GET /tuition` lists them: enough to show a
/// parent what each child owes without a request per child.
///
/// Switching between them stays with the auth child switcher — this is the
/// balance beside the name, not a second source of truth for who is selected.
class TuitionChild extends Equatable {
  final int? studentId;
  final String? name;

  /// What this student still owes, in major units (AZN).
  final double balance;

  /// True for the student the payload's `charges` and `payments` describe.
  final bool selected;

  const TuitionChild({
    this.studentId,
    this.name,
    this.balance = 0,
    this.selected = false,
  });

  @override
  List<Object?> get props => [studentId, name, balance, selected];
}
