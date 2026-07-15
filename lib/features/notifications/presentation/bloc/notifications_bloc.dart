import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/usecases/get_notifications.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final GetNotifications getNotifications;

  NotificationsBloc({required this.getNotifications})
      : super(const NotificationsState()) {
    on<NotificationsFetched>(_onFetched);
    on<NotificationsRefreshed>(_onFetched);
  }

  Future<void> _onFetched(
    NotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    // A pull-to-refresh keeps the current list on screen; the first load has
    // nothing to keep, so both paths just flip the status.
    emit(state.copyWith(status: NotificationsStatus.loading));

    final result = await getNotifications(const NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: failure.message,
      )),
      // Built fresh rather than via copyWith so null ids actually clear the
      // previous ones.
      (content) => emit(NotificationsState(
        status: NotificationsStatus.loaded,
        studentId: content.studentId,
        classId: content.classId,
        items: content.items,
      )),
    );
  }
}
