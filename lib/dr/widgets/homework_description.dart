import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/l10n.dart';
import '../../core/utils/html_description.dart';
import '../theme/dr_colors.dart';

/// A homework's description as the teacher wrote it: the text with its links
/// tappable, and each YouTube video in it as a card under the text.
///
/// Links and videos open inside the app (an in-app browser — Safari View on
/// iOS, Custom Tabs on Android), so the parent does not lose the homework;
/// where that is not available, in the browser or the YouTube app.
class HomeworkDescription extends StatefulWidget {
  final String html;
  const HomeworkDescription({super.key, required this.html});

  /// Whether [html] has anything to show — the screen skips the section
  /// otherwise.
  static bool hasContent(String html) => !HtmlDescription.parse(html).isEmpty;

  @override
  State<HomeworkDescription> createState() => _HomeworkDescriptionState();
}

class _HomeworkDescriptionState extends State<HomeworkDescription> {
  late ParsedDescription _parsed = HtmlDescription.parse(widget.html);
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void didUpdateWidget(HomeworkDescription old) {
    super.didUpdateWidget(old);
    if (old.html != widget.html) _parsed = HtmlDescription.parse(widget.html);
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilt with the spans: one recognizer per link, kept to be disposed.
    _disposeRecognizers();
    final linkStyle = TextStyle(
      color: context.dr.accent,
      decoration: TextDecoration.underline,
      decorationColor: context.dr.accent,
      fontWeight: FontWeight.w500,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_parsed.hasText)
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: context.dr.textMain,
              ),
              children: [
                for (final part in _parsed.parts)
                  if (part.isLink)
                    TextSpan(
                      text: part.text,
                      style: linkStyle,
                      recognizer: _opening(part.url!),
                    )
                  else
                    TextSpan(text: part.text),
              ],
            ),
          ),
        for (final video in _parsed.videos) ...[
          if (_parsed.hasText || video != _parsed.videos.first)
            const SizedBox(height: 14),
          _VideoCard(video: video),
        ],
      ],
    );
  }

  /// A tap that opens [url], kept to be disposed.
  TapGestureRecognizer _opening(String url) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () => openHomeworkLink(context, url);
    _recognizers.add(recognizer);
    return recognizer;
  }
}

/// A YouTube video: its thumbnail with a play button; a tap plays it.
class _VideoCard extends StatelessWidget {
  final DescriptionVideo video;
  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.hwWatchVideo;

    return Semantics(
      // Its own node: without it the button and its label were folded into
      // the description's text, which a screen reader then read as one button.
      container: true,
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => openHomeworkLink(context, video.url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  video.thumbnailUrl,
                  fit: BoxFit.cover,
                  // Offline, or the video taken down: the card still plays
                  // the link.
                  errorBuilder: (_, _, _) =>
                      ColoredBox(color: context.dr.bgSurfaceLight),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xB3000000)],
                      stops: [0.45, 1],
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 60,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0000),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 32),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Row(
                    children: [
                      const Icon(Icons.smart_display_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens [url] inside the app; failing that, outside it; failing both, says
/// so.
Future<void> openHomeworkLink(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  var ok = false;
  if (uri != null) {
    for (final mode in const [
      LaunchMode.inAppBrowserView,
      LaunchMode.externalApplication,
    ]) {
      try {
        ok = await launchUrl(uri, mode: mode);
      } catch (_) {
        ok = false;
      }
      if (ok) break;
    }
  }

  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.linkCouldNotOpen)),
    );
  }
}
