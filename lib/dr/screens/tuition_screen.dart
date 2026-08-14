import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/di/injection_container.dart';
import '../../features/tuition/domain/entities/tuition_charge.dart';
import '../../features/tuition/domain/entities/tuition_payment.dart';
import '../../features/tuition/presentation/bloc/tuition_bloc.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_ring.dart';
import '../widgets/dr_widgets.dart';
import 'topup_screen.dart';

/// Port of `schedule.html`, backed by `GET /tuition` — the outstanding totals,
/// the instalment schedule and the payment ledger for the active student.
class TuitionScreen extends StatelessWidget {
  const TuitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TuitionBloc>()..add(const TuitionFetched()),
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
  /// Asks how much to pay — the server's suggestion by default, any other sum
  /// on request — then hands that amount to the top-up form.
  Future<void> _startPayment(TuitionState state) async {
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PayAmountSheet(state: state),
    );

    // Sheet dismissed without confirming.
    if (amount == null || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TopUpScreen(initialAmount: amount)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DrScaffold(
      child: BlocBuilder<TuitionBloc, TuitionState>(
        builder: (context, state) {
          final bloc = context.read<TuitionBloc>();

          return RefreshIndicator(
            onRefresh: () async => bloc.add(const TuitionRefreshed()),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const DrBackHeader(title: 'Ödəniş cədvəli', showBack: false),
                _Body(state: state, onPay: () => _startPayment(state)),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final TuitionState state;
  final VoidCallback onPay;

  const _Body({required this.state, required this.onPay});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && !state.hasData) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.status == TuitionStatus.error) {
      return _Message(
        text: state.errorMessage ?? 'Xəta baş verdi',
        onRetry: () =>
            context.read<TuitionBloc>().add(const TuitionRefreshed()),
      );
    }

    final schedule = state.schedule;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        _SummaryCards(state: state),
        const SizedBox(height: 30),
        // Nothing invoiced yet means nothing to count through — the donut
        // would just read `0/0`.
        if (state.totalCharges > 0) ...[
          Center(child: _ProgressRing(state: state)),
          const SizedBox(height: 30),
        ],
        _PayCard(state: state, onPay: onPay),
        const SizedBox(height: 32),
        const Text(
          'Ödəniş Cədvəli',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        if (schedule.isEmpty)
          _Message(text: 'Ödəniş cədvəli tapılmadı')
        else ...[
          _tableHeader(context),
          const SizedBox(height: 4),
          for (var i = 0; i < schedule.length; i++)
            _ScheduleRow(
              charge: schedule[i],
              currency: state.currency,
              last: i == schedule.length - 1,
            ),
        ],
        if (state.recentPayments.isNotEmpty) ...[
          const SizedBox(height: 32),
          const DrSectionHeader(title: 'Ödəniş tarixçəsi', fontSize: 16),
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

  Widget _tableHeader(BuildContext context) {
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
          Expanded(child: Text('ÖDƏNİŞ TARİXİ', style: s)),
          Expanded(
            child: Text(
              'ÖDƏNİŞ MƏBLƏĞİ',
              style: s,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text('STATUS', style: s, textAlign: TextAlign.right),
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
                  label: 'Təhsil haqqı',
                  value: _money(summary.balance, currency),
                  hint: state.totalCharges == 0
                      ? 'Ümumi qalıq'
                      : '${state.totalCharges} taksit üzrə',
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.percent_rounded,
                  color: summary.hasLateFee ? DrColors.red : DrColors.green,
                  label: 'Gecikmə cəriməsi',
                  value: _money(summary.lateFee, currency),
                  hint: summary.hasLateFee ? 'Gecikmə üzrə' : 'Gecikmə yoxdur',
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
                  label: 'Cari ay üçün ödəniş',
                  value: next == null ? '—' : _money(summary.dueNow, currency),
                  hint: next == null ? 'Cədvəl bağlanıb' : _dueDateText(next),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.receipt_long_rounded,
                  color: summary.hasLateFee ? DrColors.red : DrColors.green,
                  label: 'Artıq ödənilmiş məbləğ',
                  value: _money(summary.credit, currency),
                  hint: summary.hasLateFee ? 'Gecikmə üzrə' : 'Gecikmə yoxdur',
                ),
              ),

            ],
          ),
        ),
      ],
    );
  }

  String _dueDateText(TuitionCharge charge) {
    final date = charge.dueDate;
    if (date == null) return charge.statusLabel ?? 'Tarix yoxdur';
    final text = DateFormat('dd/MM/yyyy').format(date);
    return charge.isOverdue ? 'Gecikib · $text' : text;
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

/// Instalments settled out of the whole schedule.
class _ProgressRing extends StatelessWidget {
  final TuitionState state;
  const _ProgressRing({required this.state});

  @override
  Widget build(BuildContext context) {
    return DrRing(
      progress: state.progress,
      size: 220,
      stroke: 24,
      color: context.dr.accent,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ödəniş',
            style: TextStyle(fontSize: 14, color: context.dr.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            '${state.paidCount}/${state.totalCharges}',
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
      subtitle = 'İndi ödənilməli: ${_money(summary.dueNow, state.currency)}';
    } else if (summary.credit > 0) {
      subtitle = 'Hesabda artıq: ${_money(summary.credit, state.currency)}';
    } else if (summary.isSettled) {
      subtitle = 'Borc yoxdur. Öncədən ödəniş edə bilərsiniz.';
    } else {
      subtitle = 'Vaxtı çatmış borc yoxdur.';
    }

    return DrCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ödəniş bölməsi',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: context.dr.textMuted),
          ),
          const SizedBox(height: 24),
          DrPrimaryButton(label: 'Ödəniş et', onTap: onPay),
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
              _statusText(),
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
  String _statusText() {
    if (charge.isOverdue && !charge.isPaid) {
      return charge.statusLabel == null
          ? 'Gecikib'
          : '${charge.statusLabel} · gecikib';
    }
    return charge.statusLabel ??
        switch (charge.status) {
          TuitionChargeStatus.paid => 'Ödənilib',
          TuitionChargeStatus.partial => 'Qismən',
          TuitionChargeStatus.open => 'Ödənilməyib',
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
      title: payment.methodLabel ?? payment.method ?? 'Ödəniş',
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

/// Amount picker: the suggested sums as one-tap options, plus a free-form
/// field for a parent who wants to pay more or less.
class _PayAmountSheet extends StatefulWidget {
  final TuitionState state;
  const _PayAmountSheet({required this.state});

  @override
  State<_PayAmountSheet> createState() => _PayAmountSheetState();
}

class _PayAmountSheetState extends State<_PayAmountSheet> {
  final _custom = TextEditingController();

  /// Index into [_options]; equal to their length when "other" is chosen.
  late int _selected;
  late final List<_AmountOption> _options;

  String? _error;

  @override
  void initState() {
    super.initState();
    _options = _buildOptions();
    _selected = 0;
  }

  /// The sums worth one tap, largest intent first and never the same figure
  /// twice — a schedule where the next instalment *is* the whole balance
  /// should not offer it as two separate choices.
  List<_AmountOption> _buildOptions() {
    final state = widget.state;
    final summary = state.summary;
    final next = state.nextCharge;

    final options = <_AmountOption>[];
    void add(String label, String hint, double amount) {
      if (amount <= 0) return;
      if (options.any((o) => o.amount == amount)) return;
      options.add(_AmountOption(label: label, hint: hint, amount: amount));
    }

    add('Tam borc', 'Bütün qalıq borc', state.payableAmount);
    // if (next != null) {
    //   final date = next.dueDate;
    //   add(
    //     'Növbəti taksit',
    //     date == null ? 'Cədvəl üzrə' : DateFormat('dd/MM/yyyy').format(date),
    //     next.amount,
    //   );
    // }
    add('İndi ödənilməli', 'Vaxtı çatmış borc', summary.dueNow);

    return options;
  }

  bool get _isOther => _selected == _options.length;

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_isOther) {
      Navigator.of(context).pop(_options[_selected].amount);
      return;
    }

    // Parents type `12,50` as readily as `12.50`.
    final text = _custom.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(text);

    if (amount == null) {
      setState(() => _error = 'Məbləği düzgün daxil edin');
      return;
    }
    if (amount <= 0) {
      setState(() => _error = 'Məbləğ 0-dan böyük olmalıdır');
      return;
    }

    Navigator.of(context).pop(double.parse(amount.toStringAsFixed(2)));
  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.state.currency;

    return Padding(
      // Lifts the sheet clear of the keyboard while the custom field is open.
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
              const Text(
                'Ödəniş məbləği',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Təklif olunan məbləği seçin və ya özünüz yazın.',
                style: TextStyle(fontSize: 13, color: context.dr.textMuted),
              ),
              const SizedBox(height: 20),
              for (var i = 0; i < _options.length; i++) ...[
                _OptionRow(
                  label: _options[i].label,
                  hint: _options[i].hint,
                  trailing: _money(_options[i].amount, currency),
                  selected: _selected == i,
                  onTap: () => setState(() {
                    _selected = i;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 10),
              ],
              _OptionRow(
                label: 'Başqa məbləğ',
                hint: 'İstədiyiniz məbləği yazın',
                trailing: null,
                selected: _isOther,
                onTap: () => setState(() {
                  _selected = _options.length;
                  _error = null;
                }),
              ),
              if (_isOther) ...[
                const SizedBox(height: 14),
                DrTextField(
                  hint: '0.00',
                  icon: Icons.payments_outlined,
                  controller: _custom,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) => _submit(),
                ),
              ],
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
                label: 'Davam et',
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

/// One preset sum on the payment sheet.
class _AmountOption {
  final String label;
  final String hint;
  final double amount;

  const _AmountOption({
    required this.label,
    required this.hint,
    required this.amount,
  });
}

/// Selectable row on the payment sheet — the accent ring is what marks the
/// choice, so it reads the same on both themes.
class _OptionRow extends StatelessWidget {
  final String label;
  final String hint;
  final String? trailing;
  final bool selected;
  final VoidCallback onTap;

  const _OptionRow({
    required this.label,
    required this.hint,
    required this.trailing,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? context.dr.accentSoft : context.dr.bgDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? context.dr.accent : context.dr.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? context.dr.accent : context.dr.border,
                  width: 2,
                ),
              ),
              child: selected
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: context.dr.accent,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: context.dr.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              Text(
                trailing!,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
              child: const Text('Yenidən cəhd et'),
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
