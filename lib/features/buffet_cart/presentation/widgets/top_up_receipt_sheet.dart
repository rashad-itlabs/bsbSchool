import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_dates.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../dr/services/public_downloads.dart';
import '../../../../dr/services/receipt_pdf.dart';
import '../../../../dr/theme/dr_colors.dart';
import '../../../../dr/widgets/dr_widgets.dart';
import '../../domain/entities/buffet_card.dart';
import '../../domain/entities/buffet_top_up.dart';

/// What the gateway sent back for one balance top-up, and the same thing as a
/// PDF the parent can keep.
///
/// The receipt is built on the phone from data the card screen already has —
/// the API sends the gateway's `payload` along with every `incoming` row — so
/// nothing is downloaded and it works with no connection.
///
/// Pops with the message the caller should show once the PDF has been written;
/// a failure keeps the sheet open and says so in place.
class TopUpReceiptSheet extends StatefulWidget {
  final BuffetTopUp topUp;

  /// The card the money landed on — the student's name and card number are
  /// part of the receipt, and they live on the card, not on the payment.
  final BuffetCard? card;

  /// Seam for tests; the real writer needs a file system and asset fonts.
  final ReceiptPdf? writer;

  const TopUpReceiptSheet({
    super.key,
    required this.topUp,
    this.card,
    this.writer,
  });

  @override
  State<TopUpReceiptSheet> createState() => _TopUpReceiptSheetState();
}

class _TopUpReceiptSheetState extends State<TopUpReceiptSheet> {
  late final ReceiptPdf _writer = widget.writer ?? ReceiptPdf();

  bool _saving = false;
  String? _error;

  BuffetTopUp get _topUp => widget.topUp;
  TopUpReceipt? get _receipt => widget.topUp.receipt;

  /// The row's own amount is the money that reached the card; the payload's is
  /// what the bank took. They agree, but the first is the one being receipted.
  num? get _amount => _topUp.amount ?? _receipt?.amount;

  /// Absent details mean the row is still a payment that happened — only its
  /// bank-side particulars are missing.
  bool get _success => _receipt?.isSuccess ?? true;

  Future<void> _download() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final l10n = context.l10n;
    final document = _document(context);

    try {
      await _writer.download(document);
      if (!mounted) return;
      Navigator.of(context).pop(l10n.receiptSaved(PublicDownloads.locationName));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = l10n.receiptSaveFailed;
      });
    }
  }

  /// The receipt as the writer wants it: wording resolved here, where there is
  /// a context to resolve it with.
  ReceiptDocument _document(BuildContext context) {
    final l10n = context.l10n;
    final amount = _amount;
    final bankRows = _bankRows(context);
    return ReceiptDocument(
      title: l10n.receiptTitle,
      amountLabel: l10n.receiptAmount,
      amount: amount == null ? '—' : _money(amount),
      statusLine: _statusLine(context),
      success: _success,
      sections: [
        ReceiptSection(rows: _paymentRows(context)),
        if (bankRows.isNotEmpty)
          ReceiptSection(title: l10n.receiptPaymentDetails, rows: bankRows),
      ],
      footer: l10n.receiptFooter,
      fileName: _fileName(context),
    );
  }

  /// Who paid what, for whom — the half of the receipt that is the school's.
  List<(String, String)> _paymentRows(BuildContext context) {
    final l10n = context.l10n;
    final card = widget.card;
    final date = _topUp.date ?? _receipt?.datetime;
    return [
      if (card != null && card.fullName.isNotEmpty)
        (l10n.receiptStudent, card.fullName),
      if (card?.className != null) (l10n.receiptClass, card!.className!),
      if (card?.cardId1 != null) (l10n.cardNumberLabel, card!.cardId1!),
      // The API's own wording for the row, which is what the school books it
      // as; the app's label only stands in when it sends none.
      (l10n.receiptPurpose, _topUp.purpose ?? l10n.topUpLabel),
      if (date != null) (l10n.receiptDate, AppDates.shortWithTime(context, date)),
    ];
  }

  /// The numbers a bank asks for when a payment has to be traced.
  List<(String, String)> _bankRows(BuildContext context) {
    final l10n = context.l10n;
    final receipt = _receipt;
    if (receipt == null) return const [];

    final fee = receipt.fee;
    return [
      if (receipt.pan != null) (l10n.receiptCard, receipt.pan!),
      if (receipt.system != null) (l10n.receiptSystem, receipt.system!),
      if (receipt.issuer != null) (l10n.receiptIssuer, receipt.issuer!),
      if (receipt.method != null) (l10n.receiptMethod, receipt.method!),
      if (receipt.approval != null) (l10n.receiptApproval, receipt.approval!),
      if (receipt.rrn != null) (l10n.receiptRrn, receipt.rrn!),
      if (receipt.reference != null)
        (l10n.receiptReference, receipt.reference!),
      if (fee != null) (l10n.receiptFee, _money(fee)),
      if (receipt.message != null) (l10n.receiptStatus, receipt.message!),
    ];
  }

  String _statusLine(BuildContext context) =>
      _success ? context.l10n.receiptSuccess : context.l10n.receiptFailed;

  /// Dated so the parent can tell two receipts apart in their Downloads, and
  /// carrying the approval code so two in the same minute cannot collide.
  String _fileName(BuildContext context) {
    final date = _topUp.date ?? _receipt?.datetime;
    final parts = <String>[
      context.l10n.receiptFileBase,
      if (date != null) DateFormat('yyyy-MM-dd-HHmm').format(date),
      ?(_receipt?.approval ?? _receipt?.rrn),
    ];
    return parts.join('-');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final amount = _amount;
    final bankRows = _bankRows(context);
    final error = _error;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      decoration: BoxDecoration(
        color: context.dr.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.dr.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: (_success ? DrColors.green : DrColors.redStrong)
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _success ? Icons.check_rounded : Icons.close_rounded,
                color: _success ? DrColors.green : DrColors.redStrong,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              amount == null ? '—' : '+ ${_money(amount)}',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              _statusLine(context),
              style: TextStyle(fontSize: 13, color: context.dr.textMuted),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _RowGroup(rows: _paymentRows(context)),
                    if (bankRows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          l10n.receiptNoDetails,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.dr.textMuted,
                          ),
                        ),
                      )
                    else ...[
                      const SizedBox(height: 18),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          l10n.receiptPaymentDetails,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.dr.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _RowGroup(rows: bankRows),
                    ],
                  ],
                ),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: DrColors.redStrong),
              ),
            ],
            const SizedBox(height: 20),
            DrPrimaryButton(
              label: l10n.receiptDownload,
              trailingIcon: Icons.download_rounded,
              loading: _saving,
              onTap: _download,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// Label/value rows the way the receipt reads on paper.
class _RowGroup extends StatelessWidget {
  final List<(String label, String value)> rows;
  const _RowGroup({required this.rows});

  @override
  Widget build(BuildContext context) {
    return DrListCard(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        for (var i = 0; i < rows.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              border: i == rows.length - 1
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    rows[i].$1,
                    style: TextStyle(fontSize: 12, color: context.dr.textMuted),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: SelectableText(
                    rows[i].$2,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

String _money(num value) => '${value.toStringAsFixed(2)} ₼';
