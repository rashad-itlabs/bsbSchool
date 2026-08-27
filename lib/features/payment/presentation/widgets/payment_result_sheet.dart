import 'package:flutter/material.dart';

import '../../../../dr/theme/dr_colors.dart';
import '../../../../dr/widgets/dr_widgets.dart';
import '../../domain/entities/payment_result.dart';
import '../../../../core/l10n/l10n.dart';

/// What `/payment/status` came back with, in the app's own words. The message
/// is the API's — it already knows whether the money landed.
///
/// Shared by the buffet top-up and the school-fee flows: the outcome reads the
/// same either way, only [balanceLabel] differs (a wallet has a balance to
/// report back, a fee payment leaves a remaining debt).
class PaymentResultSheet extends StatelessWidget {
  final PaymentResult result;

  /// Wording for the figure the API sends back after settling. Null takes the
  /// default ("current balance").
  final String? balanceLabel;

  /// False hides the figure entirely — a fee payment says nothing about the
  /// canteen wallet the status endpoint reports.
  final bool showBalance;

  const PaymentResultSheet({
    super.key,
    required this.result,
    this.balanceLabel,
    this.showBalance = true,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (result.status) {
      PaymentStatus.success => (Icons.check_rounded, DrColors.green),
      PaymentStatus.failed => (Icons.close_rounded, DrColors.redStrong),
      PaymentStatus.pending => (Icons.hourglass_empty_rounded, DrColors.orange),
    };

    final balance = result.balance;
    // Null on a fee payment: there is no wallet figure worth showing.
    final label = showBalance ? balanceLabel ?? context.l10n.paymentCurrentBalance : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 34),
            ),
            const SizedBox(height: 16),
            Text(
              _money(result.amount),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              result.message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.dr.textMuted),
            ),
            if (balance != null && label != null) ...[
              const SizedBox(height: 16),
              Text(
                '$label: ${_money(balance)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 24),
            DrPrimaryButton(
              label: context.l10n.commonClose,
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

String _money(num value) => '${value.toStringAsFixed(2)} ₼';
