import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/di/injection_container.dart';
import '../../core/l10n/app_dates.dart';
import '../../features/buffet_cart/domain/entities/buffet_card.dart';
import '../../features/buffet_cart/domain/entities/buffet_top_up.dart';
import '../../features/buffet_cart/domain/entities/buffet_transaction.dart';
import '../../features/buffet_cart/presentation/bloc/buffet_card_bloc.dart';
import '../../features/buffet_cart/presentation/widgets/top_up_receipt_sheet.dart';
import '../../features/payment/domain/entities/payment_result.dart';
import '../../features/payment/presentation/cubit/payment_cubit.dart';
import '../../features/payment/presentation/pages/payment_webview_page.dart';
import '../../features/payment/presentation/widgets/payment_result_sheet.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_day_picker.dart';
import '../widgets/dr_widgets.dart';
import '../../core/l10n/l10n.dart';

/// Port of `idcard.html`, backed by `GET /getBuffetCart` — the daily-limit
/// card, the barcode card slider and the recent buffet purchases.
class FoodCardScreen extends StatelessWidget {
  const FoodCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<BuffetCardBloc>()..add(const BuffetCardFetched()),
        ),
        BlocProvider(create: (_) => sl<PaymentCubit>()),
      ],
      child: const _FoodCardView(),
    );
  }
}

class _FoodCardView extends StatefulWidget {
  const _FoodCardView();

  @override
  State<_FoodCardView> createState() => _FoodCardViewState();
}

class _FoodCardViewState extends State<_FoodCardView> {
  final _controller = PageController();
  int _index = 0;

  /// The inclusive day range the transactions list shows; both ends open on
  /// today.
  DateTime _fromDay = _today();
  DateTime _toDay = _today();

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _inRange(BuffetTransaction t) {
    final date = t.date;
    if (date == null) return false;
    final day = _dayOf(date);
    return !day.isBefore(_fromDay) && !day.isAfter(_toDay);
  }

  /// The earliest pickable day: the oldest purchase the API returned, or a
  /// year back when there is nothing older.
  static DateTime _earliestDay(List<BuffetTransaction> transactions) {
    final today = _today();
    var first = DateTime(today.year - 1, today.month, today.day);
    for (final d in transactions.map((t) => t.date).whereType<DateTime>()) {
      if (d.isBefore(first)) first = _dayOf(d);
    }
    return first;
  }

  /// The start can't go past the end, so the picker stops at [_toDay].
  Future<void> _pickFromDay(List<BuffetTransaction> transactions) async {
    final picked = await showDrDayPicker(
      context: context,
      initialDate: _fromDay,
      firstDate: _earliestDay(transactions),
      lastDate: _toDay,
    );
    if (picked != null && mounted) setState(() => _fromDay = picked);
  }

  /// The end can't come before the start, nor after today.
  Future<void> _pickToDay() async {
    final picked = await showDrDayPicker(
      context: context,
      initialDate: _toDay,
      firstDate: _fromDay,
      lastDate: _today(),
    );
    if (picked != null && mounted) setState(() => _toDay = picked);
  }

  String _dayLabel(BuildContext context, DateTime day) => day == _today()
      ? context.l10n.homeworkToday
      : AppDates.short(context, day);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  Future<void> _addBalanceBlocked() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(context.l10n.paymentUnavailable)
      ),
    );
  }

  /// Asks for the amount, opens the bank page the server minted for it, and
  /// reports whatever `/payment/status` says once the parent is back.
  ///
  /// Card data never touches the app: it only carries a reference around. The
  /// balance is credited by the gateway's callback, so the card is reloaded
  /// from the API rather than adjusted locally.
  Future<void> _addBalance() async {
    final payment = context.read<PaymentCubit>();
    if (payment.state.isBusy) return;

    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddBalanceSheet(),
    );

    // Sheet dismissed without confirming.
    if (amount == null || !mounted) return;

    final session = await payment.start(amount);
    if (!mounted) return;

    if (session == null) {
      _toast(payment.state.errorMessage ?? context.l10n.paymentCouldNotStart);
      payment.reset();
      return;
    }

    final signal = await Navigator.of(context).push<PaymentReturn>(
      MaterialPageRoute(builder: (_) => PaymentWebViewPage(session: session)),
    );
    if (!mounted) return;

    // The return URL is only a signal; the outcome always comes from the API.
    final result = await payment.confirm(
      session.reference,
      bankSaidSuccess: signal == PaymentReturn.success,
    );
    if (!mounted) return;

    if (result == null) {
      _toast(
        payment.state.errorMessage ?? context.l10n.paymentStatusUnavailable,
      );
      payment.reset();
      return;
    }

    if (result.isSuccess) {
      context.read<BuffetCardBloc>().add(const BuffetCardRefreshed());
    }

    // Backed out before paying: still unpaid and nothing happened, so there is
    // nothing worth interrupting the parent with.
    final backedOut = signal == PaymentReturn.cancelled && result.isPending;
    if (!backedOut) await _showResult(result);

    if (mounted) payment.reset();
  }

  /// The outcome, with the balance the API reported after settling.
  Future<void> _showResult(PaymentResult result) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: !result.isPending,
      builder: (_) => PaymentResultSheet(result: result),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return DrScaffold(
      child: BlocBuilder<BuffetCardBloc, BuffetCardState>(
        builder: (context, state) {
          final bloc = context.read<BuffetCardBloc>();
          return RefreshIndicator(
            onRefresh: () async => bloc.add(const BuffetCardRefreshed()),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                DrBackHeader(
                  title: context.l10n.foodCardTitle,
                  showBack: false,
                ),
                ..._body(context, state),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _body(BuildContext context, BuffetCardState state) {
    final card = state.card;

    if (card == null && state.isLoading) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 80),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (card == null && state.status == BuffetCardStatus.error) {
      return [
        _Message(
          text: state.errorMessage ?? context.l10n.commonError,
          onRetry: () =>
              context.read<BuffetCardBloc>().add(BuffetCardRefreshed()),
        ),
      ];
    }

    if (card == null) {
      return [_Message(text: context.l10n.foodCardEmpty)];
    }

    final allTransactions = state.recentTransactions;
    final transactions = allTransactions.where(_inRange).toList();
    final topUps = state.recentTopUps;

    return [
      const SizedBox(height: 4),
      SizedBox(
        // Tall enough for the crest strip the card now carries above the number.
        height: 220,
        child: PageView(
          controller: _controller,
          onPageChanged: (i) => setState(() => _index = i),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _LimitCard(card: card),
            ),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 4),
            //   child: _BarcodeCard(card: card),
            // ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(1, (i) {
          final active = i == _index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? context.dr.accent : context.dr.border,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
      const SizedBox(height: 24),
      // The button carries the whole top-up: a spinner while the link is being
      // minted and again while the outcome is read back from the API.
      BlocBuilder<PaymentCubit, PaymentState>(
        builder: (context, payment) => DrPrimaryButton(
          label: payment.stage == PaymentStage.checking
              ? context.l10n.paymentChecking
              : context.l10n.balanceTopUp,
          trailingIcon: Icons.add_card_outlined,
          loading: payment.isBusy,
          onTap: _addBalanceBlocked, /// _addBalance,
        ),
      ),
      const SizedBox(height: 28),
      DrSectionHeader(title: context.l10n.recentTransactions),
      Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(
          children: [
            Expanded(
              child: _DayFilterChip(
                caption: context.l10n.filterFrom,
                label: _dayLabel(context, _fromDay),
                onTap: () => _pickFromDay(allTransactions),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: context.dr.textMuted,
              ),
            ),
            Expanded(
              child: _DayFilterChip(
                caption: context.l10n.filterTo,
                label: _dayLabel(context, _toDay),
                onTap: _pickToDay,
              ),
            ),
          ],
        ),
      ),
      if (transactions.isEmpty)
        _Message(text: context.l10n.noTransactionsInRange)
      else
        DrListCard(
          children: [
            for (var i = 0; i < transactions.length; i++)
              _TransactionTile(
                transaction: transactions[i],
                divider: i != transactions.length - 1,
              ),
          ],
        ),
      const SizedBox(height: 28),
      DrSectionHeader(title: context.l10n.balanceTopUps),
      if (topUps.isEmpty)
        _Message(text: context.l10n.noTopUps)
      else
        DrListCard(
          children: [
            for (var i = 0; i < topUps.length; i++)
              _TopUpTile(
                topUp: topUps[i],
                card: card,
                divider: i != topUps.length - 1,
                onTap: () => _showReceipt(topUps[i], card),
              ),
          ],
        ),
    ];
  }

  /// The gateway's receipt for one top-up, with the PDF download on it. The
  /// sheet pops with the message to show once the file has been written.
  Future<void> _showReceipt(BuffetTopUp topUp, BuffetCard card) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TopUpReceiptSheet(topUp: topUp, card: card),
    );
    if (message != null && mounted) _toast(message);
  }
}

/// One end of the date range under "Recent transactions" — its caption and
/// chosen day; a tap opens the day picker.
class _DayFilterChip extends StatelessWidget {
  final String caption;
  final String label;
  final VoidCallback onTap;
  const _DayFilterChip({
    required this.caption,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: context.dr.accentSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: context.dr.accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caption,
                    style: TextStyle(fontSize: 10, color: context.dr.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.dr.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formats an AZN amount as `X.XX ₼`.
String _money(num value) => '${value.toStringAsFixed(2)} ₼';

/// Asks for the top-up amount and nothing else — the card itself is entered on
/// the payment firm's own page. Returns the amount through [Navigator.pop], or
/// null when the parent closes the sheet.
class _AddBalanceSheet extends StatefulWidget {
  const _AddBalanceSheet();

  @override
  State<_AddBalanceSheet> createState() => _AddBalanceSheetState();
}

class _AddBalanceSheetState extends State<_AddBalanceSheet> {
  final _amount = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  /// Mirrors the API's own `min:1|max:1000`, so a bad amount is caught before
  /// the round trip instead of coming back as a validation error.
  static const _min = 1.0;
  static const _max = 1000.0;

  void _submit() {
    // A comma is what the AZ keyboard offers as the decimal separator.
    final value = double.tryParse(_amount.text.trim().replaceAll(',', '.'));

    if (value == null || value <= 0) {
      setState(() => _error = context.l10n.amountEnterValid);
      return;
    }

    if (value < _min || value > _max) {
      setState(
        () => _error = context.l10n.amountRange(
          _min.toStringAsFixed(0),
          _max.toStringAsFixed(0),
        ),
      );
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lifts the sheet above the keyboard while the amount is being typed.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        decoration: BoxDecoration(
          color: context.dr.bgSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.balanceTopUp,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close, color: context.dr.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.payAtBankPage,
                style: TextStyle(fontSize: 13, color: context.dr.textMuted),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IntrinsicWidth(
                    child: TextField(
                      controller: _amount,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.center,
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      onSubmitted: (_) => _submit(),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: context.dr.textMain,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        hintText: '0',
                        hintStyle: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: context.dr.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₼',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: context.dr.textMuted,
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: DrColors.redStrong,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              DrPrimaryButton(
                label: context.l10n.commonConfirm,
                trailingIcon: Icons.arrow_forward,
                onTap: _submit,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final BuffetTransaction transaction;
  final bool divider;
  const _TransactionTile({required this.transaction, this.divider = true});

  @override
  Widget build(BuildContext context) {
    final date = transaction.date;
    final subtitle = date == null
        ? '—'
        : DateFormat('dd MMM yyyy, HH:mm').format(date);
    final amount = transaction.amount;

    return DrTransactionTile(
      leading: const DrEmojiBadge(emoji: '🍽️', color: DrColors.orange),
      title: transaction.title ?? context.l10n.purchaseLabel,
      subtitle: subtitle,
      trailing: _Amount(amount == null ? '—' : '- ${_money(amount)}'),
    );
  }
}

/// A balance top-up (`incoming`). Reads as the mirror image of a purchase —
/// green and with a plus — and opens the gateway's receipt when tapped.
class _TopUpTile extends StatelessWidget {
  final BuffetTopUp topUp;
  final BuffetCard card;
  final bool divider;
  final VoidCallback onTap;

  const _TopUpTile({
    required this.topUp,
    required this.card,
    required this.onTap,
    this.divider = true,
  });

  @override
  Widget build(BuildContext context) {
    final date = topUp.date;
    final amount = topUp.amount;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DrTransactionTile(
        leading: const DrEmojiBadge(emoji: '💳', color: DrColors.green),
        // The API's own wording for the row; the app's label only stands in
        // when it sends none.
        title: topUp.purpose ?? context.l10n.topUpLabel,
        subtitle: date == null ? '—' : AppDates.shortWithTime(context, date),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              amount == null ? '—' : '+ ${_money(amount)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: DrColors.green,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.receipt_long_outlined,
              size: 16,
              color: context.dr.textMuted,
            ),
          ],
        ),
        divider: divider,
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  final String text;
  const _Amount(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
  );
}

class _LimitCard extends StatelessWidget {
  final BuffetCard card;
  const _LimitCard({required this.card});

  @override
  Widget build(BuildContext context) {
    // Money cards show the AZN balance; meal-only cards (money_balance == null)
    // show the remaining daily allowance instead.
    final money = card.moneyBalance;
    final (balanceLabel, balanceValue) = money != null
        ? (context.l10n.balanceLabel, _money(money))
        : (context.l10n.extraFeeRemaining, '${card.balance ?? 0} ₼');

    final usage = card.usage;
    final fixedUsage = card.fixedUsage;
    final usageText = (usage != null && fixedUsage != null)
        ? context.l10n.dailyUsage('$usage', '$fixedUsage')
        : null;

    return DrGlowCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card issuer strip, the way a bank card carries its bank's mark.
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(150),
                child: Image.asset(
                  'assets/appIcon/app_logo_foreground.png',
                  width: 35,
                  height: 35,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BRITISH SCHOOL IN BAKU',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                        color: context.dr.textMain,
                      ),
                    ),
                    Text(
                      'Food Cart',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.dr.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _amountColumn(
                context,
                context.l10n.cardNumberLabel,
                card.cardId1 ?? '—',
                context.dr.accent,
              ),
              _amountColumn(
                context,
                balanceLabel,
                balanceValue,
                context.dr.textMain,
                alignEnd: true,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  [
                    card.fullName,
                  ].where((e) => e != null && e.isNotEmpty).join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: context.dr.textMuted),
                ),
              ),
              if (usageText != null)
                Text(
                  usageText,
                  style: TextStyle(fontSize: 12, color: context.dr.textMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountColumn(
    BuildContext context,
    String label,
    String value,
    Color valueColor, {
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.dr.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

///
///
/// ikinci slider ucun
///
///
// class _BarcodeCard extends StatelessWidget {
//   final BuffetCard card;
//   const _BarcodeCard({required this.card});

//   @override
//   Widget build(BuildContext context) {
//     final name = card.fullName.isEmpty
//         ? 'STUDENT'
//         : card.fullName.toUpperCase();
//     final code = card.cardId1 ?? '—';

//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(24),
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Text(
//                   name,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     color: Colors.black,
//                     fontWeight: FontWeight.w700,
//                     letterSpacing: 1,
//                     fontSize: 16,
//                   ),
//                 ),
//               ),
//               Container(
//                 width: 35,
//                 height: 25,
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E)],
//                   ),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//               ),
//             ],
//           ),
//           const Spacer(),
//           const _Barcode(),
//           const SizedBox(height: 10),
//           Text(
//             code,
//             style: const TextStyle(
//               color: Colors.black,
//               fontWeight: FontWeight.w700,
//               letterSpacing: 2,
//               fontSize: 14,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 width: 8,
//                 height: 8,
//                 decoration: const BoxDecoration(
//                   color: DrColors.green,
//                   shape: BoxShape.circle,
//                 ),
//               ),
//               const SizedBox(width: 8),
//               const Text(
//                 'Ready to Scan',
//                 style: TextStyle(
//                   color: Color(0xFF666666),
//                   fontSize: 11,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//           const Spacer(),
//         ],
//       ),
//     );
//   }
// }

class _Message extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;
  const _Message({required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
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

/// Faux Code-128 barcode rendered with stripes.
class _Barcode extends StatelessWidget {
  const _Barcode();
  @override
  Widget build(BuildContext context) {
    const widths = <double>[
      3,
      1,
      2,
      1,
      1,
      3,
      2,
      1,
      1,
      2,
      3,
      1,
      2,
      2,
      1,
      1,
      3,
      1,
      2,
      1,
      2,
      3,
      1,
      1,
      2,
      1,
      3,
      2,
      1,
      1,
      2,
      1,
      3,
      1,
      2,
      2,
      1,
      3,
      1,
      2,
      1,
      1,
    ];
    return SizedBox(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < widths.length; i++)
            Container(
              width: widths[i],
              color: i.isEven ? Colors.black : Colors.transparent,
            ),
        ],
      ),
    );
  }
}
