import 'package:bsbschool/core/utils/html_description.dart';
import 'package:flutter_test/flutter_test.dart';

/// Descriptions as they sit in `home_works.description` (19.10.2026).
const _anchor =
    '<p><a href="https://youtu.be/ChqnN3cKzXQ?si=ggy3wMQscchH4Y1l">https://youtu.be/ChqnN3cKzXQ?si=ggy3wMQscchH4Y1l</a>&nbsp; &nbsp;</p><p>&nbsp;&nbsp;</p>';
const _embedOnly =
    '<p>They must know this video by heart tomorrow.</p><p>Thank you</p><figure class="media"><oembed url="https://youtu.be/ChqnN3cKzXQ?si=ggy3wMQscc"></oembed></figure>';
const _bareAndEmbed =
    '<p>https://www.youtube.com/watch?v=7cRgK0qG00E</p><figure class="media"><oembed url="https://www.youtube.com/watch?v=7cRgK0qG00E"></oembed></figure>';
const _kidsChannel =
    '<p><a href="https://www.youtubekids.com/channel/UC_qs3c0ehDvZkbiEbOj6Drg">https://www.youtubekids.com/channel/UC_qs3c0ehDvZkbiEbOj6Drg</a></p><p>&nbsp;</p><p>watch alphablocks</p><p>&nbsp;</p>';

void main() {
  group('youtubeId', () {
    test('every way a video is linked', () {
      for (final url in [
        'https://youtu.be/7cRgK0qG00E',
        'https://youtu.be/7cRgK0qG00E?si=abc',
        'https://www.youtube.com/watch?v=7cRgK0qG00E&t=42s',
        'https://m.youtube.com/watch?v=7cRgK0qG00E',
        'https://www.youtube.com/embed/7cRgK0qG00E',
        'https://youtube.com/shorts/7cRgK0qG00E',
        'https://www.youtube.com/live/7cRgK0qG00E?feature=share',
      ]) {
        expect(HtmlDescription.youtubeId(url), '7cRgK0qG00E', reason: url);
      }
    });

    test('a channel, YouTube Kids or another site is not a video', () {
      expect(
          HtmlDescription.youtubeId(
              'https://www.youtubekids.com/channel/UC_qs3c0ehDvZkbiEbOj6Drg'),
          isNull);
      expect(HtmlDescription.youtubeId('https://www.youtube.com/@bbc'), isNull);
      expect(HtmlDescription.youtubeId('https://vimeo.com/123456'), isNull);
      expect(HtmlDescription.youtubeId('not a url'), isNull);
    });
  });

  group('parse', () {
    test('an <a href> becomes a link — and its video a card', () {
      final d = HtmlDescription.parse(_anchor);
      expect(d.parts, hasLength(1));
      expect(d.parts.single.isLink, isTrue);
      expect(d.parts.single.url,
          'https://youtu.be/ChqnN3cKzXQ?si=ggy3wMQscchH4Y1l');
      expect(d.videos.single.id, 'ChqnN3cKzXQ');
    });

    test("the editor's video block, which has no text, is not lost", () {
      final d = HtmlDescription.parse(_embedOnly);
      expect(d.plainText,
          'They must know this video by heart tomorrow.\nThank you');
      expect(d.parts.any((p) => p.isLink), isFalse);
      expect(d.videos.single.id, 'ChqnN3cKzXQ');
      expect(d.videos.single.url, 'https://youtu.be/ChqnN3cKzXQ?si=ggy3wMQscc');
    });

    test('a bare URL is a link; the same video twice is one card', () {
      final d = HtmlDescription.parse(_bareAndEmbed);
      expect(d.parts.single.url, 'https://www.youtube.com/watch?v=7cRgK0qG00E');
      expect(d.videos, hasLength(1));
    });

    test('a channel link stays a link, without a card', () {
      final d = HtmlDescription.parse(_kidsChannel);
      expect(d.parts.first.isLink, isTrue);
      expect(d.parts.last.text, '\n\nwatch alphablocks');
      expect(d.videos, isEmpty);
    });

    test('a link inside a sentence keeps the words around it', () {
      final d = HtmlDescription.parse(
          '<p>Watch <a href="https://example.com/x">this page</a>, then read https://example.com/y.</p>');
      expect([for (final p in d.parts) p.toString()], [
        'Watch ',
        '[this page](https://example.com/x)',
        ', then read ',
        '[https://example.com/y](https://example.com/y)',
        '.',
      ]);
    });

    test('plain text reads as the old view did', () {
      final d = HtmlDescription.parse(
          '<p>Line one &amp; more</p><p>&nbsp;</p><p>&nbsp;</p><p>Line   two</p>');
      expect(d.plainText, 'Line one & more\n\nLine two');
      expect(d.videos, isEmpty);
    });

    test('another site\'s video block becomes a link', () {
      final d = HtmlDescription.parse(
          '<p>Watch</p><figure class="media"><oembed url="https://vimeo.com/123"></oembed></figure>');
      expect(d.parts.last.url, 'https://vimeo.com/123');
      expect(d.videos, isEmpty);
    });

    test('nothing at all', () {
      expect(HtmlDescription.parse('').isEmpty, isTrue);
      expect(HtmlDescription.parse('<p>&nbsp;</p>').isEmpty, isTrue);
    });
  });
}
