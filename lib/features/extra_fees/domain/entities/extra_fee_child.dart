import 'package:equatable/equatable.dart';

/// One student on the account, as `GET /extra_fees` lists them: what each
/// child still owes in extra fees, without a request per child.
///
/// Switching between them stays with the auth child switcher — this is the
/// figure beside the name, not a second source of truth for who is selected.
class ExtraFeeChild extends Equatable {
  final int? studentId;
  final String? name;

  /// What this student still owes in extra fees, in major units (AZN).
  final double outstanding;

  /// True for the student the payload's `fees` describe.
  final bool selected;

  const ExtraFeeChild({
    this.studentId,
    this.name,
    this.outstanding = 0,
    this.selected = false,
  });

  @override
  List<Object?> get props => [studentId, name, outstanding, selected];
}
