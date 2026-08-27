import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../dr/theme/dr_colors.dart';
import '../../domain/entities/payment_session.dart';
import '../../../../core/l10n/l10n.dart';

/// How the bank page ended, from the app's point of view. It is a *signal*
/// only — the caller still has to ask `/payment/status` for the truth.
enum PaymentReturn {
  /// The browser reached the success return URL.
  success,

  /// The browser reached the fail return URL.
  fail,

  /// The parent closed the page before the bank sent them back.
  cancelled,
}

/// Hosts the bank's checkout page and brings the parent back to the app the
/// moment the gateway redirects to one of the session's return URLs.
///
/// Pops with a [PaymentReturn]; never pops with null, so the caller always gets
/// a reason to check the status for.
class PaymentWebViewPage extends StatefulWidget {
  final PaymentSession session;

  const PaymentWebViewPage({super.key, required this.session});

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;

  int _progress = 0;
  String? _loadError;

  /// Until the first page renders the WebView draws nothing, which on iOS is
  /// indistinguishable from a broken plugin. The spinner covers that gap.
  bool _rendered = false;

  /// The return URL and a manual close can race; whoever gets here first wins.
  bool _finished = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      // Every 3-D Secure form needs it.
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // No setBackgroundColor here on purpose: on iOS it flips the WKWebView to
      // non-opaque, which is its own source of blank pages. The default white
      // is what a checkout page expects anyway.
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (mounted) setState(() => _progress = value);
          },
          onNavigationRequest: _onNavigation,
          // Server-side redirects can slip past onNavigationRequest on some
          // Android WebView builds, so the return URL is checked here too.
          onPageStarted: (url) {
            if (mounted) setState(() => _loadError = null);
            final signal = _signalFor(url);
            if (signal != null) _finish(signal);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _rendered = true);
            final signal = _signalFor(url);
            if (signal != null) _finish(signal);
          },
          onWebResourceError: (error) {
            // Sub-resources (an image, a tracker) fail all the time, and iOS
            // reports -999 for a request a redirect superseded; only a dead
            // main frame is worth showing.
            final mainFrame = error.isForMainFrame ?? true;
            if (!mainFrame || error.errorCode == -999 || !mounted) return;
            setState(() => _loadError = context.l10n.webviewLoadFailed);
          },
        ),
      )
      ..loadRequest(widget.session.paymentUrl);
  }

  /// Success/fail return URLs end the flow; bank-app deep links (`bakcell://`,
  /// `msisdn://`, ...) are handed to the OS, everything else loads in place.
  Future<NavigationDecision> _onNavigation(NavigationRequest request) async {
    final signal = _signalFor(request.url);
    if (signal != null) {
      _finish(signal);
      return NavigationDecision.prevent;
    }

    final uri = Uri.tryParse(request.url);
    final scheme = uri?.scheme.toLowerCase() ?? '';
    if (uri != null &&
        scheme.isNotEmpty &&
        scheme != 'http' &&
        scheme != 'https' &&
        scheme != 'about') {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        // No app for that scheme — staying put beats a blank page.
      }
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  /// Matches the return URLs the API handed us. The gateway appends the
  /// reference to the path and may add its own query, so this is a prefix
  /// test; the path fallback covers a gateway that rewrites the host.
  PaymentReturn? _signalFor(String url) {
    final session = widget.session;

    bool startsWith(String prefix) =>
        prefix.isNotEmpty && url.startsWith(prefix);

    if (startsWith(session.successReturnUrl) ||
        url.contains('/payment/return/success')) {
      return PaymentReturn.success;
    }
    if (startsWith(session.failReturnUrl) ||
        url.contains('/payment/return/fail')) {
      return PaymentReturn.fail;
    }
    return null;
  }

  void _finish(PaymentReturn signal) {
    if (_finished || !mounted) return;
    _finished = true;
    Navigator.of(context).pop(signal);
  }

  /// Leaving mid-payment is a real risk of double-charging, so it is confirmed.
  Future<void> _confirmClose() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.webviewStopTitle),
        content: Text(
          context.l10n.webviewStopText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.commonContinue),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              context.l10n.commonClose,
              style: TextStyle(color: DrColors.redStrong),
            ),
          ),
        ],
      ),
    );

    if (leave == true) _finish(PaymentReturn.cancelled);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // The result must always be a PaymentReturn, so the pop is done by hand
      // after the confirmation instead of letting the gesture through.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_finished) _confirmClose();
      },
      child: Scaffold(
        backgroundColor: context.dr.bgDark,
        appBar: AppBar(
          backgroundColor: context.dr.bgDark,
          foregroundColor: context.dr.textMain,
          elevation: 0,
          title: Text(context.l10n.webviewTitle, style: TextStyle(fontSize: 17)),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmClose,
          ),
          bottom: _progress < 100
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    value: _progress / 100,
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    color: context.dr.accent,
                  ),
                )
              : null,
        ),
        body: SafeArea(
          top: false,
          child: _loadError != null
              ? _ErrorView(
                  message: _loadError!,
                  onRetry: () {
                    setState(() => _loadError = null);
                    _controller.reload();
                  },
                )
              : ColoredBox(
                  color: Colors.white,
                  child: Stack(
                    children: [
                      WebViewWidget(controller: _controller),
                      if (!_rendered)
                        const Center(
                          child: CircularProgressIndicator(
                            color: DrColors.green,
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: TextStyle(fontSize: 14, color: context.dr.textMuted),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: Text(context.l10n.commonRetry)),
        ],
      ),
    );
  }
}
