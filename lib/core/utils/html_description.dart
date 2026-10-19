/// A teacher's homework description, from the website's editor (CKEditor)
/// HTML into what the app can show: text with its links, and the YouTube
/// videos in it.
///
/// Measured 19.10.2026: of the descriptions with a link, 50 carry an
/// `<a href>`, some a bare URL in the text, and some the editor's video block
/// — `<figure class="media"><oembed url="…"></oembed></figure>`, which has no
/// text at all, so stripping the tags (as the app did) dropped the video
/// without a trace; 41 point at YouTube.
library;

/// One run of a description: plain text, or a link — its words and target.
class DescriptionPart {
  final String text;
  final String? url;

  const DescriptionPart(this.text, {this.url});

  bool get isLink => url != null;

  @override
  String toString() => isLink ? '[$text]($url)' : text;
}

/// A YouTube video in a description: its id (for the thumbnail) and the
/// address to open, as the teacher wrote it (it may carry a start time).
class DescriptionVideo {
  final String id;
  final String url;

  const DescriptionVideo({required this.id, required this.url});

  String get thumbnailUrl => 'https://img.youtube.com/vi/$id/hqdefault.jpg';
}

class ParsedDescription {
  final List<DescriptionPart> parts;

  /// Each video once, in the order it first appears.
  final List<DescriptionVideo> videos;

  const ParsedDescription({this.parts = const [], this.videos = const []});

  String get plainText => parts.map((p) => p.text).join();

  bool get hasText => plainText.trim().isNotEmpty;

  bool get isEmpty => !hasText && videos.isEmpty;
}

class HtmlDescription {
  HtmlDescription._();

  static final _oembed = RegExp(
      r'''<oembed\b[^>]*?\burl\s*=\s*["']([^"']+)["'][^>]*>(?:\s*</oembed>)?''',
      caseSensitive: false);
  static final _anchor = RegExp(
      r'''<a\b[^>]*?\bhref\s*=\s*["']([^"']+)["'][^>]*>(.*?)</a\s*>''',
      caseSensitive: false,
      dotAll: true);
  static final _bareUrl = RegExp(r'''https?://[^\s<>"']+''');
  static final _tag = RegExp(r'<[^>]*>');

  static ParsedDescription parse(String html) {
    final videos = <String, DescriptionVideo>{};
    final otherMedia = <String>[];

    void noteVideo(String url) {
      final id = youtubeId(url);
      if (id != null) videos.putIfAbsent(id, () => DescriptionVideo(id: id, url: url));
    }

    // The editor's video blocks: kept aside, then taken out of the text.
    var source = html.replaceAllMapped(_oembed, (m) {
      final url = _decode(m.group(1)!).trim();
      if (youtubeId(url) != null) {
        noteVideo(url);
      } else if (url.isNotEmpty) {
        otherMedia.add(url);
      }
      return '';
    });

    // Line structure, before the tags go.
    source = source
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(
            RegExp(r'</(p|div|li|h[1-6]|figure|blockquote)\s*>',
                caseSensitive: false),
            '\n')
        .replaceAll(RegExp(r'<li\b[^>]*>', caseSensitive: false), '• ');

    final parts = <DescriptionPart>[];
    void addText(String raw) {
      final text = _decode(raw.replaceAll(_tag, ''));
      if (text.isEmpty) return;
      // A bare URL in the text is a link too.
      var at = 0;
      for (final m in _bareUrl.allMatches(text)) {
        final url = _trimTrailing(m.group(0)!);
        if (m.start > at) parts.add(DescriptionPart(text.substring(at, m.start)));
        parts.add(DescriptionPart(url, url: url));
        noteVideo(url);
        at = m.start + url.length;
      }
      if (at < text.length) parts.add(DescriptionPart(text.substring(at)));
    }

    var at = 0;
    for (final m in _anchor.allMatches(source)) {
      if (m.start > at) addText(source.substring(at, m.start));
      final url = _decode(m.group(1)!).trim();
      final words = _decode(m.group(2)!.replaceAll(_tag, '')).trim();
      if (url.startsWith('http://') || url.startsWith('https://')) {
        parts.add(DescriptionPart(words.isEmpty ? url : words, url: url));
        noteVideo(url);
      } else {
        // `mailto:`, a relative path — nothing the app can open: the words.
        addText(words);
      }
      at = m.end;
    }
    if (at < source.length) addText(source.substring(at));

    // A non-YouTube video block would vanish otherwise: list it as a link.
    for (final url in otherMedia) {
      parts
        ..add(const DescriptionPart('\n'))
        ..add(DescriptionPart(url, url: url));
    }

    return ParsedDescription(
      parts: _tidy(parts),
      videos: videos.values.toList(),
    );
  }

  /// The YouTube video id in [url] — `youtu.be/<id>`, `watch?v=<id>`,
  /// `/embed/<id>`, `/shorts/<id>`, `/live/<id>`; null for anything else
  /// (a channel, YouTube Kids, another site).
  static String? youtubeId(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;
    final host = uri.host
        .toLowerCase()
        .replaceFirst(RegExp(r'^(www\.|m\.|music\.)'), '');
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    String? id;
    if (host == 'youtu.be') {
      id = segments.isEmpty ? null : segments.first;
    } else if (host == 'youtube.com' || host == 'youtube-nocookie.com') {
      if (segments.length == 1 && segments.first == 'watch') {
        id = uri.queryParameters['v'];
      } else if (segments.length >= 2 &&
          const {'embed', 'shorts', 'live', 'v'}.contains(segments.first)) {
        id = segments[1];
      }
    }
    return id != null && RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id)
        ? id
        : null;
  }

  /// A URL ends before closing punctuation the sentence put after it.
  static String _trimTrailing(String url) =>
      url.replaceFirst(RegExp(r'[.,;:!?)\]]+$'), '');

  static String _decode(String text) => text
      .replaceAllMapped(RegExp(r'&#(\d+);'),
          (m) => String.fromCharCode(int.parse(m.group(1)!)))
      .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'),
          (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)))
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');

  /// Spaces collapsed, at most one blank line, nothing hanging at either end
  /// — the old plain-text view's rules, applied across the parts.
  static List<DescriptionPart> _tidy(List<DescriptionPart> parts) {
    final out = <DescriptionPart>[];
    for (final part in parts) {
      if (part.isLink) {
        out.add(part);
        continue;
      }
      final text = part.text
          .replaceAll(' ', ' ')
          .replaceAll(RegExp(r'[ \t]+'), ' ')
          .replaceAll(RegExp(r' *\n *'), '\n')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n');
      if (text.isNotEmpty) out.add(DescriptionPart(text));
    }

    // Merge neighbouring text runs, so the blank-line rule holds between them.
    final merged = <DescriptionPart>[];
    for (final part in out) {
      if (!part.isLink && merged.isNotEmpty && !merged.last.isLink) {
        final joined = (merged.removeLast().text + part.text)
            .replaceAll(RegExp(r'\n{3,}'), '\n\n');
        merged.add(DescriptionPart(joined));
      } else {
        merged.add(part);
      }
    }

    // Trim the whole description's ends.
    while (merged.isNotEmpty && !merged.first.isLink) {
      final t = merged.first.text.trimLeft();
      if (t.isNotEmpty) {
        merged[0] = DescriptionPart(t);
        break;
      }
      merged.removeAt(0);
    }
    while (merged.isNotEmpty && !merged.last.isLink) {
      final t = merged.last.text.trimRight();
      if (t.isNotEmpty) {
        merged[merged.length - 1] = DescriptionPart(t);
        break;
      }
      merged.removeLast();
    }
    return merged;
  }
}
