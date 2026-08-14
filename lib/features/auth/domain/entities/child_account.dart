import 'package:equatable/equatable.dart';

/// One student linked to a parent account — an entry of the login response's
/// `info` array. Carries the credentials the school issued for the child, so
/// the parent can hand them over (see `PassScreen`).
class ChildAccount extends Equatable {
  final int? childId;
  final int? classId;
  final String className;
  final String childName;
  final String childSurname;

  /// The student's own login for the app (`std_<id>@bsb.edu.az`).
  final String email;
  final String password;

  /// Reference shown on payment orders — e.g. "RA3139".
  final String paymentId;

  const ChildAccount({
    this.childId,
    this.classId,
    this.className = '',
    this.childName = '',
    this.childSurname = '',
    this.email = '',
    this.password = '',
    this.paymentId = '',
  });

  /// "Rashad Ali" — falls back to whichever half the response carried.
  String get fullName =>
      [childName, childSurname].where((p) => p.trim().isNotEmpty).join(' ');

  @override
  List<Object?> get props => [
        childId,
        classId,
        className,
        childName,
        childSurname,
        email,
        password,
        paymentId,
      ];
}
