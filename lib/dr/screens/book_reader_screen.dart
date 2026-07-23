import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../features/library/domain/entities/book.dart';
import '../services/book_download_service.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';

/// Reads a library book's PDF. When the student has downloaded it, the on-device
/// copy is read so the book opens offline; otherwise it streams from the public
/// storage URL (no bearer token needed).
class BookReaderScreen extends StatefulWidget {
  final Book book;

  const BookReaderScreen({super.key, required this.book});

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  final _controller = PdfViewerController();
  final _downloads = BookDownloadService();

  /// Set when the document fails to load; the viewer stays blank underneath,
  /// so we cover it with our own message rather than Syncfusion's dialog.
  String? _error;
  int _page = 0;
  int _pageCount = 0;

  /// The on-device copy the viewer reads from when present; null means the PDF
  /// is streamed from the network instead.
  File? _localFile;
  bool _downloaded = false;
  bool _downloading = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _loadLocal();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// If a download already exists, open it from disk instead of the network.
  Future<void> _loadLocal() async {
    final file = await _downloads.localFile(widget.book);
    if (file != null && mounted) {
      setState(() {
        _localFile = file;
        _downloaded = true;
      });
    }
  }

  Future<void> _download() async {
    if (widget.book.fileUrl == null || _downloading) return;
    setState(() {
      _downloading = true;
      _progress = 0;
    });
    try {
      final file = await _downloads.download(
        widget.book,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (!mounted) return;
      setState(() {
        _downloaded = true;
        _downloading = false;
        // Adopt the local copy only if the viewer is still on the network
        // source, so a document that's already open isn't reloaded.
        _localFile ??= file;
      });
      _toast('Kitab telefona yükləndi');
    } catch (_) {
      if (!mounted) return;
      setState(() => _downloading = false);
      _toast('Yükləmə alınmadı');
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.dr.bgSurface,
        title: const Text('Yüklənmiş faylı sil?'),
        content: const Text(
          'Kitab telefondan silinəcək. İnternet olduqda yenidən oxuya bilərsiniz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ləğv et'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _downloads.delete(widget.book);
      if (mounted) {
        setState(() => _downloaded = false);
        _toast('Yüklənmiş fayl silindi');
      }
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final fileUrl = widget.book.fileUrl;

    return Scaffold(
      backgroundColor: context.dr.bgDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: DrBackHeader(
                title: widget.book.title,
                trailing: fileUrl == null ? null : _downloadButton(context),
              ),
            ),
            Expanded(child: _viewer(fileUrl)),
            if (_pageCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('$_page / $_pageCount',
                    style:
                        TextStyle(fontSize: 12, color: context.dr.textMuted)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _viewer(String? fileUrl) {
    if (fileUrl == null) return _message('Bu kitabın faylı yoxdur');
    if (_error != null) return _message(_error!);

    if (_localFile != null) {
      return SfPdfViewer.file(
        _localFile!,
        controller: _controller,
        canShowScrollHead: false,
        onDocumentLoaded: _onLoaded,
        onDocumentLoadFailed: _onFailed,
        onPageChanged: _onPageChanged,
      );
    }
    return SfPdfViewer.network(
      fileUrl,
      controller: _controller,
      canShowScrollHead: false,
      onDocumentLoaded: _onLoaded,
      onDocumentLoadFailed: _onFailed,
      onPageChanged: _onPageChanged,
    );
  }

  void _onLoaded(PdfDocumentLoadedDetails details) => setState(() {
        _pageCount = details.document.pages.count;
        _page = _controller.pageNumber;
      });

  void _onFailed(PdfDocumentLoadFailedDetails details) => setState(() {
        _error = 'Kitab açılmadı: ${details.description}';
      });

  void _onPageChanged(PdfPageChangedDetails details) =>
      setState(() => _page = details.newPageNumber);

  /// Header action: download → progress ring → downloaded (tap to delete).
  Widget _downloadButton(BuildContext context) {
    if (_downloading) {
      return _circle(
        context,
        background: context.dr.bgSurface,
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            value: _progress == 0 ? null : _progress,
            strokeWidth: 2.5,
            color: DrColors.accentGreen,
          ),
        ),
      );
    }
    if (_downloaded) {
      return _circle(
        context,
        background: DrColors.accentGreen,
        onTap: _confirmDelete,
        child: const Icon(Icons.download_done_rounded,
            color: Colors.black, size: 22),
      );
    }
    return _circle(
      context,
      background: DrColors.accentGreen,
      onTap: _download,
      child: const Icon(Icons.download_rounded, color: Colors.black, size: 22),
    );
  }

  Widget _circle(
    BuildContext context, {
    required Color background,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(color: context.dr.border),
        ),
        child: child,
      ),
    );
  }

  Widget _message(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.dr.textMuted)),
        ),
      );
}
