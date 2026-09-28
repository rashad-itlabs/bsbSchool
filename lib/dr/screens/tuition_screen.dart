import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/di/injection_container.dart';
import '../../core/l10n/l10n.dart';
import '../../features/extra_fees/domain/entities/extra_fee.dart';
import '../../features/extra_fees/presentation/bloc/extra_fees_bloc.dart';
import '../../features/payment/domain/entities/payment_result.dart';
import '../../features/payment/domain/entities/payment_session.dart';
import '../../features/payment/presentation/cubit/payment_cubit.dart';
import '../../features/payment/presentation/pages/payment_webview_page.dart';
import '../../features/payment/presentation/widgets/payment_result_sheet.dart';
import '../../features/tuition/domain/entities/tuition_charge.dart';
import '../../features/tuition/domain/entities/tuition_payment.dart';
import '../../features/tuition/presentation/bloc/tuition_bloc.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_ring.dart';
import '../widgets/dr_widgets.dart';

/// Port of `schedule.html`, backed by `GET /tuition` and `GET /extra_fees` —
/// the outstanding totals, the instalment schedule, the payment ledger and the
/// extra fees billed to the active student.
class TuitionScreen extends StatelessWidget {
  const TuitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Both load up front: the tab badge has to say how many extra fees are
    // waiting before the parent ever opens that tab.
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<TuitionBloc>()..add(const TuitionFetched()),
        ),
        BlocProvider(
          create: (_) => sl<ExtraFeesBloc>()..add(const ExtraFeesFetched()),
        ),
        BlocProvider(create: (_) => sl<PaymentCubit>()),
      ],
      child: const _TuitionView(),
    );
  }
}

class _TuitionView extends StatefulWidget {
  const _TuitionView();

  @override
  State<_TuitionView> createState() => _TuitionViewState();
}

class _TuitionViewState extends State<_TuitionView> {
  /// The schedule opens on tuition; extra fees are the exception a parent goes
  /// looking for.
  _TuitionTab _tab = _TuitionTab.tuition;

  /// Opens the amount sheet (the remaining debt, editable) and, once the
  /// parent confirms, goes straight to the bank page for that sum through
  /// `POST /tuition/pay`.
  Future<void> _startTuitionPayment(TuitionState state) async {
    final payment = context.read<PaymentCubit>();
    if (payment.state.isBusy) return;

    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TuitionPaySheet(state: state),
    );

    // Sheet dismissed without confirming.
    if (amount == null || !mounted) return;

    await _checkout(
      amount: amount,
      tuition: true,
      start: () => payment.startTuition(amount),
    );
  }

  /// Pays one extra fee through `POST /pay/{feeId}`.
  Future<void> _payFee({required int feeId, required double amount}) async {
    if (amount <= 0) return;
    final payment = context.read<PaymentCubit>();
    await _checkout(
      amount: amount,
      start: () => payment.startFees(feeId: feeId, amount: amount),
    );
  }

  /// Runs one payment end to end: [start] mints the link, the bank page
  /// opens, then the outcome is read back from the status route — the tuition
  /// one when [tuition] is set.
  ///
  /// Card details never touch the app — it only carries a reference around.
  /// The debt is cleared by the gateway's server-to-server callback, so both
  /// tabs are reloaded from the API rather than adjusted locally.
  Future<void> _checkout({
    required double amount,
    required Future<PaymentSession?> Function() start,
    bool tuition = false,
  }) async {
    final payment = context.read<PaymentCubit>();
    if (payment.state.isBusy) return;

    final session = await start();
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
      tuition: tuition,
    );
    if (!mounted) return;

    if (result == null) {
      // The card was charged and the bank sent us back on the success URL, but
      // the API would not confirm it. Reporting a bare error here is the worst
      // outcome of the lot: the parent has paid. Reload — the callback may have
      // landed already — and say plainly that it is still settling.
      if (signal == PaymentReturn.success) {
        context.read<TuitionBloc>().add(const TuitionRefreshed());
        context.read<ExtraFeesBloc>().add(const ExtraFeesRefreshed());
        await _showUnconfirmed(amount);
        if (mounted) payment.reset();
        return;
      }

      _toast(payment.state.errorMessage ?? context.l10n.paymentStatusUnavailable);
      payment.reset();
      return;
    }

    if (result.isSuccess) {
      context.read<TuitionBloc>().add(const TuitionRefreshed());
      context.read<ExtraFeesBloc>().add(const ExtraFeesRefreshed());
    }

    // Backed out before paying: still unpaid and nothing happened, so there is
    // nothing worth interrupting the parent with.
    final backedOut = signal == PaymentReturn.cancelled && result.isPending;
    if (!backedOut) {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isDismissible: !result.isPending,
        // The refreshed tabs show where the debt now stands; the status
        // payload's `balance` is the buffet wallet on the fee route.
        builder: (_) => PaymentResultSheet(result: result, showBalance: false),
      );
    }

    if (mounted) payment.reset();
  }

  /// Bank said yes, the API would not say. Built here rather than taken from a
  /// response on purpose: there is no server verdict to show, and pending is
  /// exactly what the app knows.
  Future<void> _showUnconfirmed(double amount) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => PaymentResultSheet(
        showBalance: false,
        result: PaymentResult(
          reference: '',
          status: PaymentStatus.pending,
          amount: amount,
          currency: 'AZN',
          message: context.l10n.paymentUnconfirmed,
        ),
      ),
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
      child: BlocBuilder<TuitionBloc, TuitionState>(
        builder: (context, state) {
          final bloc = context.read<TuitionBloc>();

          return RefreshIndicator(
            // Both tabs live in one scroll view, so a pull refreshes both.
            onRefresh: () async {
              bloc.add(const TuitionRefreshed());
              context.read<ExtraFeesBloc>().add(const ExtraFeesRefreshed());
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                DrBackHeader(title: context.l10n.tuitionTitle, showBack: false),
                _Body(
                  state: state,
                  tab: _tab,
                  onTabChanged: (tab) => setState(() => _tab = tab),
                  onPayTuition: () => _startTuitionPayment(state),
                  onPayFee: _payFee,
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The two halves of the bill. Charges carry a `type`, so the split is the
/// API's own, not a guess made in the UI.
enum _TuitionTab { tuition, extra }

/// Pay one extra fee: `POST /pay/{feeId}` takes the row id, and the amount is
/// what is still owed on it.
typedef _PayFee = void Function({required int feeId, required double amount});

class _Body extends StatelessWidget {
  final TuitionState state;
  final _TuitionTab tab;
  final ValueChanged<_TuitionTab> onTabChanged;

  /// Opens the tuition amount sheet.
  final VoidCallback onPayTuition;

  /// Starts the bank checkout for one extra fee.
  final _PayFee onPayFee;

  const _Body({
    required this.state,
    required this.tab,
    required this.onTabChanged,
    required this.onPayTuition,
    required this.onPayFee,
  });

  @override
  Widget build(BuildContext context) {
    // The tab bar stays put while either side loads: the badge comes from the
    // extra-fees bloc, so it must not wait on the tuition request.
    final extraPending = context.select<ExtraFeesBloc, int>(
      (bloc) => bloc.state.pendingCount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TabSelector(
          active: tab,
          extraCount: extraPending,
          onChanged: onTabChanged,
        ),
        const SizedBox(height: 24),
        switch (tab) {
          _TuitionTab.tuition => _TuitionSection(
            state: state,
            onPay: onPayTuition,
          ),
           _TuitionTab.extra => _ExtraFeesTabBody(onPayFee: onPayFee),
        },
      ],
    );
  }
}

/// The tuition tab with its own loading and error states — each tab reports on
/// its own request, so a failed extra-fees call cannot blank the schedule.
class _TuitionSection extends StatelessWidget {
  final TuitionState state;
  final VoidCallback onPay;

  const _TuitionSection({required this.state, required this.onPay});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && !state.hasData) return const _Spinner();

    if (state.status == TuitionStatus.error) {
      return _Message(
        text: state.errorMessage ?? context.l10n.commonError,
        onRetry: () =>
            context.read<TuitionBloc>().add(const TuitionRefreshed()),
      );
    }

    return _TuitionTabBody(state: state, onPay: onPay);
  }
}

/// Segmented switch under the header. The active half is the filled lime the
/// rest of the app uses for a chosen chip, so it reads on either theme.
class _TabSelector extends StatelessWidget {
  final _TuitionTab active;

  /// Shown as a badge so a parent sees there is something on the other tab
  /// without opening it.
  final int extraCount;

  final ValueChanged<_TuitionTab> onChanged;

  const _TabSelector({
    required this.active,
    required this.extraCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.dr.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.dr.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: context.l10n.tuitionTabTuition,
              active: active == _TuitionTab.tuition,
              onTap: () => onChanged(_TuitionTab.tuition),
            ),
          ),
          Expanded(
            child: _Segment(
              label: context.l10n.tuitionTabExtra,
              badge: extraCount == 0 ? null : '$extraCount',
              active: active == _TuitionTab.extra,
              onTap: () => onChanged(_TuitionTab.extra),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final String? badge;
  final bool active;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    this.badge,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? DrColors.accentGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: DrColors.accentGreen.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? Colors.black : context.dr.textMuted,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.black.withValues(alpha: 0.15)
                      : context.dr.bgSurfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.black : context.dr.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The tuition half: the account totals, the instalment donut, the pay button
/// and the schedule, followed by the ledger.
class _TuitionTabBody extends StatelessWidget {
  final TuitionState state;
  final VoidCallback onPay;

  const _TuitionTabBody({required this.state, required this.onPay});

  @override
  Widget build(BuildContext context) {
    final schedule = state.tuitionSchedule;
    final paid = schedule.where((c) => c.isPaid).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryCards(state: state),
        const SizedBox(height: 30),
        // Nothing invoiced yet means nothing to count through — the donut
        // would just read `0/0`.
        if (schedule.isNotEmpty) ...[
          Center(
            child: _ProgressRing(paid: paid, total: schedule.length),
          ),
          const SizedBox(height: 30),
        ],
        _PayCard(state: state, onPay: onPay),
        const SizedBox(height: 32),
        Text(
          context.l10n.tuitionScheduleTitle,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        if (schedule.isEmpty)
          _Message(text: context.l10n.tuitionScheduleEmpty)
        else
          _ScheduleTable(charges: schedule, currency: state.currency),
        if (state.recentPayments.isNotEmpty) ...[
          const SizedBox(height: 32),
          DrSectionHeader(title: context.l10n.tuitionHistoryTitle, fontSize: 16),
          DrListCard(
            children: [
              for (var i = 0; i < state.recentPayments.length; i++)
                _PaymentTile(
                  payment: state.recentPayments[i],
                  currency: state.currency,
                  divider: i != state.recentPayments.length - 1,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The extra-fees tab, backed by `GET /extra_fees`: books, trips, exam entries
/// — anything billed outside the tuition schedule. Each fee carries its own
/// remaining balance, so each can be paid on its own.
class _ExtraFeesTabBody extends StatelessWidget {
  final _PayFee onPayFee;

  const _ExtraFeesTabBody({required this.onPayFee});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExtraFeesBloc, ExtraFeesState>(
      builder: (context, state) {
        if (state.isLoading && !state.hasData) return const _Spinner();

        if (state.status == ExtraFeesStatus.error) {
          return _Message(
            text: state.errorMessage ?? context.l10n.commonError,
            onRetry: () =>
                context.read<ExtraFeesBloc>().add(const ExtraFeesRefreshed()),
          );
        }

        if (state.isEmpty) {
          return _Message(text: context.l10n.extraFeesEmpty);
        }

        final fees = state.sortedFees;
        final currency = state.currency;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ExtraFeeSummaryCards(state: state),
            const SizedBox(height: 24),
            _OutstandingCard(state: state, onPayFee: onPayFee),
            const SizedBox(height: 32),
            Text(
              context.l10n.extraFeesListTitle,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < fees.length; i++) ...[
              if (i != 0) const SizedBox(height: 12),
              _FeeCard(
                fee: fees[i],
                currency: currency,
                onPay: () =>
                    onPayFee(feeId: fees[i].id, amount: fees[i].remaining),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// The four extra-fee totals, straight from the endpoint's own `summary`.
class _ExtraFeeSummaryCards extends StatelessWidget {
  final ExtraFeesState state;
  const _ExtraFeeSummaryCards({required this.state});

  @override
  Widget build(BuildContext context) {
    final summary = state.summary;
    final currency = state.currency;

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.category_rounded,
                  color: DrColors.purple,
                  label: context.l10n.extraFeesTotal,
                  value: _money(summary.total, currency),
                  hint: context.l10n.extraFeesCountLabel(state.fees.length),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.pending_actions_rounded,
                  color: summary.hasOutstanding
                      ? DrColors.orange
                      : DrColors.green,
                  label: context.l10n.extraFeesOutstanding,
                  value: _money(summary.outstanding, currency),
                  hint: summary.hasOutstanding
                      ? context.l10n.extraFeesPendingCount(summary.unpaidCount)
                      : context.l10n.extraFeesAllPaid,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.check_circle_outline_rounded,
                  color: context.dr.accent,
                  label: context.l10n.extraFeesPaidAmount,
                  value: _money(summary.paid, currency),
                  hint: summary.total <= 0
                      ? context.l10n.extraFeesNoPayment
                      : context.l10n.extraFeesProgressDone(
                          (summary.progress * 100).round(),
                        ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.warning_amber_rounded,
                  color: summary.hasOverdue ? DrColors.red : DrColors.green,
                  label: context.l10n.extraFeesOverdueCount,
                  value: '${summary.overdueCount}',
                  hint: summary.hasOverdue ? context.l10n.extraFeesOverdueHint : context.l10n.tuitionNoLateFee,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// What is still owed, above the list.
///
/// `POST /pay/{id}` settles one fee at a time, so there is no "pay everything"
/// button: with several fees outstanding each card carries its own. A lone
/// payable fee is the exception — repeating it here saves a scroll.
class _OutstandingCard extends StatelessWidget {
  final ExtraFeesState state;
  final _PayFee onPayFee;

  const _OutstandingCard({required this.state, required this.onPayFee});

  @override
  Widget build(BuildContext context) {
    final amount = state.payableAmount;

    if (amount <= 0) {
      return DrCard(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: context.dr.accent,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.extraFeesAllDone,
                style: TextStyle(fontSize: 13, color: context.dr.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    final payable = state.payableFees;
    final single = payable.length == 1 ? payable.single : null;

    return DrCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.extraFeesListTitle,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            state.summary.hasOverdue
                ? context.l10n.extraFeesOverdueDebt(
                    _money(amount, state.currency),
                  )
                : context.l10n.extraFeesPayableAmount(
                    _money(amount, state.currency),
                  ),
            style: TextStyle(fontSize: 13, color: context.dr.textMuted),
          ),
          if (single != null) ...[
            const SizedBox(height: 24),
            DrPrimaryButton(
              label: context.l10n.payNow,
              trailingIcon: Icons.arrow_forward,
              onTap: () => onPayFee(feeId: single.id, amount: single.remaining),
              loading: context.select<PaymentCubit, bool>(
                (cubit) => cubit.state.isBusy,
              ),
            ),
          ] else if (payable.length > 1) ...[
            const SizedBox(height: 14),
            Text(
              context.l10n.extraFeesPayEachSeparately,
              style: TextStyle(fontSize: 12, color: context.dr.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// One extra fee: what it is, when it is due, and what is left on it.
class _FeeCard extends StatelessWidget {
  final ExtraFee fee;
  final String currency;
  final VoidCallback onPay;

  const _FeeCard({
    required this.fee,
    required this.currency,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusText) = _status(context);
    final due = fee.dueDate;
    final last = fee.lastPayment;

    return DrCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_outlined,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fee.title ?? context.l10n.extraFeeFallbackTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (fee.description != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        fee.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.dr.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusPill(text: statusText, color: statusColor),
            ],
          ),
          const SizedBox(height: 16),
          // Part-paid fees get a bar: the numbers alone do not show how far
          // along it is at a glance.
          if (fee.isPartial) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: fee.progress,
                minHeight: 6,
                backgroundColor: context.dr.bgSurfaceLight,
                valueColor: AlwaysStoppedAnimation(context.dr.accent),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Expanded(
                child: _FeeFact(
                  label: context.l10n.extraFeeAmount,
                  value: _money(fee.amount, currency),
                ),
              ),
              Expanded(
                child: _FeeFact(
                  label: context.l10n.extraFeePaid,
                  value: _money(fee.paid, currency),
                ),
              ),
              Expanded(
                child: _FeeFact(
                  label: context.l10n.extraFeeRemaining,
                  value: _money(fee.remaining, currency),
                  valueColor: fee.isOutstanding ? statusColor : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.event_rounded,
                size: 15,
                color: fee.isOverdue
                    ? DrColors.redStrong
                    : context.dr.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  due == null
                      ? context.l10n.extraFeeNoDueDate
                      : fee.isOverdue
                      ? context.l10n.dueDateOverdueLabel(
                          DateFormat('dd/MM/yyyy').format(due),
                        )
                      : context.l10n.dueDateLabel(
                          DateFormat('dd/MM/yyyy').format(due),
                        ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: fee.isOverdue
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: fee.isOverdue
                        ? DrColors.redStrong
                        : context.dr.textMuted,
                  ),
                ),
              ),
            ],
          ),
          if (last != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 15,
                  color: context.dr.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.lastPaymentLabel(
                    DateFormat('dd/MM/yyyy').format(last),
                  ),
                  style: TextStyle(fontSize: 12, color: context.dr.textMuted),
                ),
              ],
            ),
          ],
          // The server decides whether a fee can be paid; a closed or settled
          // one simply has no button.
          if (fee.isPayable && fee.isOutstanding) ...[
            const SizedBox(height: 16),
            _PayFeeButton(
              label: context.l10n.payWithAmount(_money(fee.remaining, currency)),
              onTap: onPay,
            ),
          ],
        ],
      ),
    );
  }

  /// The server's own wording wins; the fallbacks only cover a missing label.
  (Color, String) _status(BuildContext context) {
    if (fee.isOverdue && fee.isOutstanding) {
      return (DrColors.redStrong, fee.statusLabel ?? context.l10n.statusOverdue);
    }
    return switch (fee.status) {
      ExtraFeeStatus.paid => (context.dr.accent, fee.statusLabel ?? context.l10n.statusPaid),
      ExtraFeeStatus.partial => (DrColors.orange, fee.statusLabel ?? context.l10n.statusPartial),
      ExtraFeeStatus.unpaid => (
        DrColors.orange,
        fee.statusLabel ?? context.l10n.statusUnpaid,
      ),
      ExtraFeeStatus.other => (context.dr.textMuted, fee.statusLabel ?? '—'),
    };
  }
}

/// One label/value pair inside a fee card.
class _FeeFact extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _FeeFact({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: context.dr.textMuted),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: valueColor ?? context.dr.textMain,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Per-fee pay button: outlined rather than the filled lime, so a card full of
/// them does not compete with the page's one primary action.
class _PayFeeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PayFeeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // One checkout at a time: a second link minted mid-flight would strand the
    // first reference with nothing polling it.
    final busy = context.select<PaymentCubit, bool>(
      (cubit) => cubit.state.isBusy,
    );

    return GestureDetector(
      onTap: busy ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: busy ? 0.5 : 1,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.dr.accentSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.dr.accent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.dr.accent,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 16, color: context.dr.accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// The schedule table, shared by both tabs.
class _ScheduleTable extends StatelessWidget {
  final List<TuitionCharge> charges;
  final String currency;

  const _ScheduleTable({required this.charges, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context),
        const SizedBox(height: 4),
        for (var i = 0; i < charges.length; i++)
          _ScheduleRow(
            charge: charges[i],
            currency: currency,
            last: i == charges.length - 1,
          ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    final s = TextStyle(
      fontSize: 11,
      color: context.dr.textMuted,
      letterSpacing: 0.5,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Expanded(child: Text(context.l10n.tuitionColumnDate, style: s)),
          Expanded(
            child: Text(
              context.l10n.tuitionColumnAmount,
              style: s,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(context.l10n.tuitionColumnStatus, style: s, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

/// The four totals above the fold. Principal and interest are shown side by
/// side because together they add up to the balance in the first card.
class _SummaryCards extends StatelessWidget {
  final TuitionState state;
  const _SummaryCards({required this.state});

  @override
  Widget build(BuildContext context) {
    final summary = state.summary;
    final next = state.nextCharge;
    final currency = state.currency;

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.account_balance_wallet_rounded,
                  color: context.dr.accent,
                  label: context.l10n.tuitionTabTuition,
                  value: _money(summary.balance, currency),
                  hint: state.totalCharges == 0
                      ? context.l10n.tuitionTotalDue
                      : context.l10n.tuitionInstalmentsCount(state.totalCharges),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.percent_rounded,
                  color: summary.hasLateFee ? DrColors.red : DrColors.green,
                  label: context.l10n.tuitionLateFee,
                  value: _money(summary.lateFee, currency),
                  hint: summary.hasLateFee ? context.l10n.tuitionLateFeeHint : context.l10n.tuitionNoLateFee,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.event_rounded,
                  color: DrColors.teal,
                  label: context.l10n.tuitionCurrentMonth,
                  value: next == null ? '—' : _money(summary.dueNow, currency),
                  hint: next == null
                      ? context.l10n.tuitionScheduleClosed
                      : _dueDateText(context, next),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.receipt_long_rounded,
                  color: summary.hasLateFee ? DrColors.red : DrColors.green,
                  label: context.l10n.tuitionCredit,
                  value: _money(summary.credit, currency),
                  hint: summary.hasLateFee ? context.l10n.tuitionLateFeeHint : context.l10n.tuitionNoLateFee,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _dueDateText(BuildContext context, TuitionCharge charge) {
    final date = charge.dueDate;
    if (date == null) return charge.statusLabel ?? context.l10n.tuitionNoDate;
    final text = DateFormat('dd/MM/yyyy').format(date);
    return charge.isOverdue ? context.l10n.overdueWithDate(text) : text;
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String hint;

  const _SummaryCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return DrCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: context.dr.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.dr.textMain,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 6),
          Text(
            hint,
            style: TextStyle(
              fontSize: 11,
              color: context.dr.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Instalments settled out of the schedule on screen.
class _ProgressRing extends StatelessWidget {
  final int paid;
  final int total;

  const _ProgressRing({required this.paid, required this.total});

  @override
  Widget build(BuildContext context) {
    return DrRing(
      progress: total == 0 ? 0 : paid / total,
      size: 220,
      stroke: 24,
      color: context.dr.accent,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.tuitionRingLabel,
            style: TextStyle(fontSize: 14, color: context.dr.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            '$paid/$total',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PayCard extends StatelessWidget {
  final TuitionState state;
  final VoidCallback onPay;

  const _PayCard({required this.state, required this.onPay});

  @override
  Widget build(BuildContext context) {
    final summary = state.summary;

    // What the parent most needs to know before tapping: an overdue amount if
    // there is one, otherwise the credit or a clean slate.
    final String subtitle;
    if (summary.dueNow > 0) {
      subtitle = context.l10n.tuitionDueNowAmount(
        _money(summary.dueNow, state.currency),
      );
    } else if (summary.credit > 0) {
      subtitle = context.l10n.tuitionCreditAmount(
        _money(summary.credit, state.currency),
      );
    } else if (summary.isSettled) {
      subtitle = context.l10n.tuitionNoDebt;
    } else {
      subtitle = context.l10n.tuitionNothingDueYet;
    }

    return DrCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.tuitionPaySection,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: context.dr.textMuted),
          ),
          const SizedBox(height: 24),
          DrPrimaryButton(
            label: context.l10n.payNow,
            onTap: onPay,
            loading: context.select<PaymentCubit, bool>(
              (cubit) => cubit.state.isBusy,
            ),
          ),
        ],
      ),
    );
  }
}

/// One instalment: due date, amount and where it stands.
class _ScheduleRow extends StatelessWidget {
  final TuitionCharge charge;
  final String currency;
  final bool last;

  const _ScheduleRow({
    required this.charge,
    required this.currency,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context);
    final date = charge.dueDate;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: context.dr.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    date == null ? '—' : DateFormat('dd/MM/yyyy').format(date),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              _money(charge.amount, currency),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              _statusText(context),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }

  /// The server's own wording wins; the fallbacks only cover a missing label.
  String _statusText(BuildContext context) {
    if (charge.isOverdue && !charge.isPaid) {
      return charge.statusLabel == null
          ? context.l10n.statusOverdue
          : context.l10n.statusOverdueSuffix(charge.statusLabel!);
    }
    return charge.statusLabel ??
        switch (charge.status) {
          TuitionChargeStatus.paid => context.l10n.statusPaid,
          TuitionChargeStatus.partial => context.l10n.statusPartial,
          TuitionChargeStatus.open => context.l10n.statusUnpaid,
          TuitionChargeStatus.other => '—',
        };
  }

  Color _statusColor(BuildContext context) {
    if (charge.isOverdue && !charge.isPaid) return DrColors.redStrong;
    return switch (charge.status) {
      TuitionChargeStatus.paid => context.dr.accent,
      TuitionChargeStatus.partial => DrColors.orange,
      TuitionChargeStatus.open => context.dr.textMuted,
      TuitionChargeStatus.other => context.dr.textMuted,
    };
  }
}

/// One ledger entry. Started and failed attempts are listed too — a parent who
/// tried to pay needs to see why it did not land.
class _PaymentTile extends StatelessWidget {
  final TuitionPayment payment;
  final String currency;
  final bool divider;

  const _PaymentTile({
    required this.payment,
    required this.currency,
    this.divider = true,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (payment.status) {
      TuitionPaymentStatus.paid => (Icons.check_rounded, DrColors.green),
      TuitionPaymentStatus.failed => (Icons.close_rounded, DrColors.redStrong),
      TuitionPaymentStatus.refunded => (Icons.undo_rounded, DrColors.purple),
      TuitionPaymentStatus.initiated => (
        Icons.hourglass_empty_rounded,
        DrColors.orange,
      ),
      TuitionPaymentStatus.other => (Icons.credit_card_rounded, DrColors.teal),
    };

    final date = payment.date;
    final subtitle = [
      if (date != null) DateFormat('dd MMM yyyy, HH:mm').format(date),
      // The decline text is the whole point of showing a failed attempt.
      if (!payment.isPaid && payment.reason != null) payment.reason!,
    ].join(' · ');

    return DrTransactionTile(
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: payment.methodLabel ?? payment.method ?? context.l10n.tuitionRingLabel,
      subtitle: subtitle.isEmpty ? '—' : subtitle,
      divider: divider,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _money(payment.amount, currency),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            payment.statusLabel ?? '',
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }
}

/// What "Pay" opens: the remaining debt, already written in as the amount,
/// which the parent can change to pay part of it — or, with nothing owed, any
/// sum ahead. The button goes straight to the bank page.
class _TuitionPaySheet extends StatefulWidget {
  final TuitionState state;
  const _TuitionPaySheet({required this.state});

  @override
  State<_TuitionPaySheet> createState() => _TuitionPaySheetState();
}

class _TuitionPaySheetState extends State<_TuitionPaySheet> {
  late final _amount = TextEditingController(text: _debtText);
  final _focus = FocusNode();

  String? _error;

  double get _debt => widget.state.summary.balance;
  String get _debtText => _debt > 0 ? _debt.toStringAsFixed(2) : '';

  @override
  void initState() {
    super.initState();
    // Tapping the prefilled sum selects it, so typing replaces it instead of
    // appending to it.
    _focus.addListener(() {
      if (!_focus.hasFocus) return;
      _amount.selection =
          TextSelection(baseOffset: 0, extentOffset: _amount.text.length);
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Puts the whole debt back after the parent has typed something else.
  void _fillDebt() {
    _amount.text = _debtText;
    setState(() => _error = null);
  }

  void _submit() {
    // Parents type `12,50` as readily as `12.50`.
    final amount = double.tryParse(_amount.text.trim().replaceAll(',', '.'));

    if (amount == null) {
      setState(() => _error = context.l10n.tuitionAmountInvalid);
      return;
    }
    if (amount <= 0) {
      setState(() => _error = context.l10n.tuitionAmountTooSmall);
      return;
    }

    Navigator.of(context).pop(double.parse(amount.toStringAsFixed(2)));
  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.state.currency;

    return Padding(
      // Lifts the sheet clear of the keyboard.
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.dr.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.tuitionAmountSheetTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              // The debt, tappable to put it back into the field.
              GestureDetector(
                onTap: _debt > 0 ? _fillDebt : null,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: context.dr.bgSurfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.dr.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded,
                          size: 20, color: context.dr.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.l10n.tuitionOutstandingDebt,
                          style: TextStyle(
                              fontSize: 13, color: context.dr.textMuted),
                        ),
                      ),
                      Text(
                        _money(_debt, currency),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DrTextField(
                hint: '0.00',
                icon: Icons.payments_outlined,
                controller: _amount,
                focusNode: _focus,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.tuitionAmountSheetEditHint,
                style: TextStyle(fontSize: 12, color: context.dr.textMuted),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: DrColors.redStrong,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              DrPrimaryButton(
                label: context.l10n.payNow,
                trailingIcon: Icons.lock_outline_rounded,
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

/// First-load placeholder, shared by both tabs.
class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 80),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _Message extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;
  const _Message({required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 20),
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

/// The API states its currency; only AZN has a glyph worth showing.
String _money(num value, String currency) {
  final text = value.toStringAsFixed(2);
  return currency == 'AZN' ? '$text ₼' : '$text $currency';
}
