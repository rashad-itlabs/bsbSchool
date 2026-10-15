import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/di/injection_container.dart';
import '../../features/notifications/domain/entities/notification_item.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../../features/notifications/presentation/notifications_feed_signal.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';
import '../../core/l10n/l10n.dart';

/// Port of `notifications.html`, backed by `GET /notifications` — the message
/// feed for the logged-in student (both personal and class-wide items, and
/// since 15.10.2026 the school's push announcements) plus the local
/// notification-preference toggles.
class NotificationsScreen extends StatelessWidget {
  /// A student signed in on their own: the filter pills are theirs (homework,
  /// system) instead of a parent's (attendance, exam, canteen, system). The
  /// shell passes it from the signed-in account.
  final bool forStudent;

  const NotificationsScreen({super.key, this.forStudent = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationsBloc>()..add(const NotificationsFetched()),
      child: _RefetchOnLanguageChange(
        child: _FollowPushes(
          child: _NotificationsView(forStudent: forStudent),
        ),
      ),
    );
  }
}

/// Keeps the feed in step with the pushes the device gets.
///
/// A push that arrives in the foreground or is tapped
/// ([NotificationsFeedSignal]) asks for the feed again — the tab stays
/// mounted with whatever it loaded at start-up. A tapped school announcement
/// is opened as soon as a feed that has it is in; after a cold start that is
/// the tab's own first load.
class _FollowPushes extends StatefulWidget {
  final Widget child;
  const _FollowPushes({required this.child});

  @override
  State<_FollowPushes> createState() => _FollowPushesState();
}

class _FollowPushesState extends State<_FollowPushes> {
  final _signal = NotificationsFeedSignal.instance;

  @override
  void initState() {
    super.initState();
    _signal.addListener(_onPush);
  }

  @override
  void dispose() {
    _signal.removeListener(_onPush);
    super.dispose();
  }

  void _onPush() =>
      context.read<NotificationsBloc>().add(const NotificationsRefreshed());

  /// Opens the tapped announcement, if one is waiting. The id is taken either
  /// way: one tap opens it once, and an entry the feed does not have (an old
  /// server, a push for another account on this phone) is not retried later.
  void _openPending(BuildContext context, NotificationsState state) {
    if (!_signal.hasPendingOpen) return;
    final id = _signal.takeOpenPushId();
    final item = state.items
        .where((i) => i.isSchoolPush && i.id == id)
        .firstOrNull;
    if (item != null) showNotificationSheet(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationsBloc, NotificationsState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == NotificationsStatus.loaded,
      listener: _openPending,
      child: widget.child,
    );
  }
}

/// Asks for the feed again when the app language changes.
///
/// The server writes the titles and texts in the language the request names
/// (`lang`), and this tab stays mounted behind the bottom bar — without this,
/// a parent who switched language would keep reading the feed in the old one
/// until they pulled to refresh. The tab keeps building while hidden, so the
/// new feed is usually in before they open it.
class _RefetchOnLanguageChange extends StatefulWidget {
  final Widget child;
  const _RefetchOnLanguageChange({required this.child});

  @override
  State<_RefetchOnLanguageChange> createState() =>
      _RefetchOnLanguageChangeState();
}

class _RefetchOnLanguageChangeState extends State<_RefetchOnLanguageChange> {
  String? _language;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    // The first pass only records it — the bloc's own first fetch is running.
    if (_language != null && _language != language) {
      context.read<NotificationsBloc>().add(const NotificationsRefreshed());
    }
    _language = language;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _NotificationsView extends StatelessWidget {
  final bool forStudent;
  const _NotificationsView({required this.forStudent});

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
                        child: Text(
                          context.l10n.notificationsTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 44),
                    ],
                  ),
                ),
                // Hidden only while the very first load has nothing to show.
                if (state.items.isNotEmpty ||
                    state.status == NotificationsStatus.loaded) ...[
                  _CategoryBar(state: state, forStudent: forStudent),
                  const SizedBox(height: 18),
                ],
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

/// The filter pills, in a fixed order. Every pill is always there — even one
/// that is still empty: attendance, exam and canteen entries arrive once the
/// server generates them, and a pill that came and went with the data would
/// move the others around under the parent's thumb.
///
/// Which pills, by who is signed in (owner, 15.10.2026):
/// * a parent — attendance, exam, canteen, system; homework entries and
///   teachers' messages are listed under "all" only;
/// * a student — homework, system. Homework entries reach students alone
///   (backend `HomeworkFeed::forApp`), and the attendance, exam and canteen
///   notices are meant for parents.
class _CategoryBar extends StatelessWidget {
  final NotificationsState state;
  final bool forStudent;
  const _CategoryBar({required this.state, required this.forStudent});

  /// Null is "all".
  static final _parentPills =
      <(NotificationCategory?, String Function(AppL10n))>[
    (null, (l10n) => l10n.commonAll),
    (NotificationCategory.attendance, (l10n) => l10n.notifFilterAttendance),
    (NotificationCategory.exam, (l10n) => l10n.notifFilterExam),
    (NotificationCategory.cafeteria, (l10n) => l10n.notifFilterCafeteria),
    (NotificationCategory.system, (l10n) => l10n.notifFilterSystem),
  ];

  static final _studentPills =
      <(NotificationCategory?, String Function(AppL10n))>[
    (null, (l10n) => l10n.commonAll),
    (NotificationCategory.homework, (l10n) => l10n.notifFilterHomework),
    (NotificationCategory.system, (l10n) => l10n.notifFilterSystem),
  ];

  @override
  Widget build(BuildContext context) {
    final pills = forStudent ? _studentPills : _parentPills;
    return DrChipBar(
      labels: [for (final (_, label) in pills) label(context.l10n)],
      selectedIndex: pills.indexWhere((pill) => pill.$1 == state.category),
      onSelected: (i) => context.read<NotificationsBloc>().add(
        NotificationsCategorySelected(pills[i].$1),
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
        onRetry: () => context.read<NotificationsBloc>().add(
          const NotificationsRefreshed(),
        ),
      );
    }

    final items = state.visibleItems;
    if (items.isEmpty) {
      // "Nothing here" reads differently from "nothing at all".
      return _Message(
        text: state.items.isEmpty
            ? context.l10n.notificationsEmpty
            : context.l10n.notificationsEmptyFilter,
      );
    }

    return DrListCard(
      children: [
        for (var i = 0; i < items.length; i++)
          _tile(context, items[i], divider: i != items.length - 1),
      ],
    );
  }

  Widget _tile(
    BuildContext context,
    NotificationItem item, {
    bool divider = true,
  }) {
    final from = _senderOf(context, item);
    final subtitle = [
      if (item.message.isNotEmpty) item.message,
      ?from,
    ].join('\n');

    // The whole row opens the entry: a long announcement reads better on its
    // own, with the full date and copyable text.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showNotificationSheet(context, item),
      child: DrTransactionTile(
        leading: DrEmojiBadge(emoji: _emojiFor(item), color: context.dr.accent),
        title: _titleOf(context, item),
        subtitle: subtitle.isEmpty ? '—' : subtitle,
        divider: divider,
        trailing: Text(
          _trailingLabel(item),
          style: TextStyle(fontSize: 12, color: context.dr.textMuted),
        ),
      ),
    );
  }

  /// Class-wide messages get the class name; personal ones get the sent date.
  String _trailingLabel(NotificationItem item) {
    if (item.isForClass && item.className != null) return item.className!;
    final date = item.date;
    if (date != null) return DateFormat('dd MMM').format(date.toLocal());
    return '';
  }
}

String _titleOf(BuildContext context, NotificationItem item) =>
    item.title.isEmpty ? context.l10n.notificationFallback : item.title;

/// A teacher's name, or — for a school announcement, which the server sends
/// without one — the school itself.
String? _senderOf(BuildContext context, NotificationItem item) =>
    item.sender ??
    (item.isSchoolPush ? context.l10n.notificationFromSchool : null);

/// By the entry's category — the same split as the pills — rather than by
/// words in its text, which put a teacher's "exam tomorrow" note next to real
/// exam results. The first four match the settings card's emoji.
String _emojiFor(NotificationItem item) => switch (item.category) {
  NotificationCategory.system => '📣',
  NotificationCategory.attendance => '🏫',
  NotificationCategory.exam => '📚',
  NotificationCategory.cafeteria => '☕',
  NotificationCategory.homework => '📝',
  NotificationCategory.teacher => item.isForClass ? '👥' : '🔔',
};

/// One entry in full: title, who sent it and when, and the whole text —
/// selectable, so a parent can copy a date or a phone number out of it.
Future<void> showNotificationSheet(
  BuildContext context,
  NotificationItem item,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _NotificationSheet(item: item),
  );
}

class _NotificationSheet extends StatelessWidget {
  final NotificationItem item;
  const _NotificationSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final from = _senderOf(context, item);
    final date = item.date;
    final meta = [
      ?from,
      if (date != null) DateFormat('dd MMM yyyy, HH:mm').format(date.toLocal()),
      if (item.isForClass && item.className != null) item.className!,
    ].join(' · ');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: context.dr.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: context.dr.border),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.dr.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DrEmojiBadge(
                emoji: _emojiFor(item),
                color: context.dr.accent,
                size: 52,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleOf(context, item),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.dr.textMain,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.dr.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (item.message.isNotEmpty) ...[
            const SizedBox(height: 18),
            Flexible(
              child: SingleChildScrollView(
                child: SelectableText(
                  item.message,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: context.dr.textMain,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          DrPrimaryButton(
            label: context.l10n.commonClose,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
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
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.dr.textMuted),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ],
      ),
    );
  }
}
