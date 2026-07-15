import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/notifications_content.dart';

abstract class NotificationsRepository {
  /// Notifications for the logged-in student, scoped to their class.
  Future<Either<Failure, NotificationsContent>> getNotifications();
}
