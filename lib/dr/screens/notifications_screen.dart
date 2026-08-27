import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/di/injection_container.dart';
import '../../features/notifications/domain/entities/notification_item.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';
import '../../core/l10n/l10n.dart';

/// Port of `notifications.html`, backed by `GET /notifications` — the message
/// feed for the logged-in student (both personal and class-wide items) plus the
/// local notification-preference toggles.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationsBloc>()..add(const NotificationsFetched()),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    return DrScaffold(
      child: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          final bloc = context.read<NotificationsBloc>();

          return RefreshIndicator(
            onRefresh: () async => bloc.add(const NotificationsRefreshed()),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // Header: matches the tab layout (decorative spacers + title).
                Padding(
                  padding: EdgeInsets.only(bottom: 30),
                  child: Row(
                    children: [
                      SizedBox(width: 44),
                      Expanded(
                        child: Text(context.l10n.notificationsTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600)),
                      ),
                      SizedBox(width: 44),
                    ],
                  ),
                ),
                _Feed(state: state),
                const SizedBox(height: 28),
              ],
            ),
          );
        },
      ),
    );
  }

}

/// The server-driven "Son bildirişlər" list with its loading / error / empty
/// states.
class _Feed extends StatelessWidget {
  final NotificationsState state;
  const _Feed({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.status == NotificationsStatus.error) {
      return _Message(
        text: state.errorMessage ?? context.l10n.commonError,
        onRetry: () => context
            .read<NotificationsBloc>()
            .add(const NotificationsRefreshed()),
      );
    }

    final items = state.recentItems;
    if (items.isEmpty) {
      return _Message(text: context.l10n.notificationsEmpty);
    }

    return DrListCard(
      children: [
        for (var i = 0; i < items.length; i++)
          _tile(context, items[i], divider: i != items.length - 1),
      ],
    );
  }

  Widget _tile(BuildContext context, NotificationItem item,
      {bool divider = true}) {
    final subtitle = [
      if (item.message.isNotEmpty) item.message,
      if (item.sender != null) item.sender!,
    ].join('\n');

    return DrTransactionTile(
      leading: DrEmojiBadge(emoji: _emojiFor(item), color: context.dr.accent),
      title: item.title.isEmpty ? context.l10n.notificationFallback : item.title,
      subtitle: subtitle.isEmpty ? '—' : subtitle,
      divider: divider,
      trailing: Text(
        _trailingLabel(item),
        style: TextStyle(fontSize: 12, color: context.dr.textMuted),
      ),
    );
  }

  /// Class-wide messages get the class name; personal ones get the sent date.
  String _trailingLabel(NotificationItem item) {
    if (item.isForClass && item.className != null) return item.className!;
    if (item.date != null) return DateFormat('dd MMM').format(item.date!);
    return '';
  }

  String _emojiFor(NotificationItem item) {
    final text = '${item.title} ${item.message}'.toLowerCase();
    if (text.contains('exam') || text.contains('imtahan')) return '📚';
    if (text.contains('buffet') || text.contains('bufet')) return '☕';
    if (text.contains('attendance') || text.contains('davamiyyət')) return '🏫';
    if (item.isForClass) return '👥';
    return '🔔';
  }
}

class _Message extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;
  const _Message({required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.dr.textMuted)),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: Text(context.l10n.commonRetry)),
          ],
        ],
      ),
    );
  }
}
