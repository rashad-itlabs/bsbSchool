import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/notifications_content.dart';
import '../repositories/notifications_repository.dart';

class GetNotifications implements UseCase<NotificationsContent, NoParams> {
  final NotificationsRepository repository;
  const GetNotifications(this.repository);

  @override
  Future<Either<Failure, NotificationsContent>> call(NoParams params) {
    return repository.getNotifications();
  }
}
