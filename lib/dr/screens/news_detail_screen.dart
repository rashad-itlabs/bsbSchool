import 'package:flutter/material.dart';

import '../../core/utils/html_text.dart';
import '../../features/news/domain/entities/news_item.dart';
import '../../features/news/presentation/widgets/news_image.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';
import '../../core/l10n/l10n.dart';

/// Full view of one news entry, reached by tapping a slide on the dashboard.
/// The slider only has room for two lines of each field; here the image, the
/// whole title and the whole (HTML-stripped) text are shown.
class NewsDetailScreen extends StatelessWidget {
  final NewsItem item;

  const NewsDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // Read at build time, so a language switch re-renders the entry in the
    // new language without reloading it.
    final language = Localizations.localeOf(context).languageCode;
    final body = stripHtmlTags(item.descriptionIn(language));

    return DrScaffold(
      child: ListView(
        children: [
          DrBackHeader(title: context.l10n.newsTitle),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: NewsImage(url: item.image),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            item.titleIn(language),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: context.dr.textMain,
            ),
          ),
          const SizedBox(height: 20),
          if (body.isNotEmpty)
            DrCard(
              radius: 20,
              child: SelectableText(
                body,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: context.dr.textMain,
                ),
              ),
            )
          else
            // An entry published with a headline only; say so instead of
            // leaving an empty card under the title.
            Row(
              children: [
                Icon(Icons.notes_rounded, size: 16, color: context.dr.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.newsNoBody,
                    style:
                        TextStyle(fontSize: 13, color: context.dr.textMuted),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
