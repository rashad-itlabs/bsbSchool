import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/di/injection_container.dart';
import '../../features/notifications/domain/entities/notification_item.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';

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

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  // Local, client-side delivery preferences — kept in the UI as in the HTML
  // port; the server feed itself is not filtered by these.
  final _settings = {'attendance': true, 'cafeteria': true, 'exam': true};

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
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Row(
                    children: const [
                      SizedBox(width: 44),
                      Expanded(
                        child: Text('Bildirişlər',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600)),
                      ),
                      SizedBox(width: 44),
                    ],
                  ),
                ),
                const DrSectionHeader(title: 'Son bildirişlər'),
                _Feed(state: state),
                const SizedBox(height: 28),
                const DrSectionHeader(title: 'Bildiriş parametrləri'),
                DrListCard(
                  children: [
                    _settingRow('attendance', '🏫', 'Davamiyyət',
                        'Uşağın məktəbə gəlişi və dərsdən çıxışı barədə bildirişlər.'),
                    _settingRow('cafeteria', '☕', 'Bufet',
                        'Uşağın bufetdə nəyə xərclədiyi barədə bildirişlər.'),
                    _settingRow('exam', '📚', 'İmtahanlar',
                        'Uşağın imtahan nəticələri və imtahana girilməsi barədə bildirişlər.',
                        last: true),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _settingRow(String key, String emoji, String title, String subtitle,
      {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: context.dr.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style:
                        TextStyle(fontSize: 12, color: context.dr.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DrSwitch(
            value: _settings[key]!,
            onChanged: (v) => setState(() => _settings[key] = v),
          ),
        ],
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
        text: state.errorMessage ?? 'Xəta baş verdi',
        onRetry: () => context
            .read<NotificationsBloc>()
            .add(const NotificationsRefreshed()),
      );
    }

    final items = state.recentItems;
    if (items.isEmpty) {
      return const _Message(text: 'Hələ bildiriş yoxdur.');
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
      leading: DrEmojiBadge(emoji: _emojiFor(item), color: DrColors.accentGreen),
      title: item.title.isEmpty ? 'Bildiriş' : item.title,
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
            TextButton(onPressed: onRetry, child: const Text('Yenidən cəhd et')),
          ],
        ],
      ),
    );
  }
}
