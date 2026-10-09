import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/news_bloc.dart';

/// Reloads the [NewsBloc] above it when the app language changes.
///
/// The slides already re-render from `translations`, but a backend that
/// predates the field sends only the language the feed was requested in —
/// and the dashboard creates the bloc once, so without this the slider stays
/// in the old language until the app restarts. The refresh keeps the current
/// slides on screen while it runs.
class NewsLanguageReload extends StatefulWidget {
  final Widget child;

  const NewsLanguageReload({super.key, required this.child});

  @override
  State<NewsLanguageReload> createState() => _NewsLanguageReloadState();
}

class _NewsLanguageReloadState extends State<NewsLanguageReload> {
  Locale? _locale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    // The first call is the mount; the bloc's own `NewsFetched` covers it.
    if (_locale != null && _locale != locale) {
      context.read<NewsBloc>().add(const NewsRefreshed());
    }
    _locale = locale;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
