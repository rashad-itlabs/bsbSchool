import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/l10n/l10n.dart';
import '../../features/auth/domain/entities/child_account.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../theme/dr_colors.dart';
import 'dr_widgets.dart';

/// Aktiv uşaq deaktivdirsə, bütün səhifələrin üstündə bağlanmayan modal göstərir.
class ChildBlockedGate extends StatelessWidget {
  final Widget child;

  const ChildBlockedGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final blocked = context.select<AuthBloc, ChildAccount?>(
          (bloc) => bloc.state.blockedChild,
    );

    return PopScope(
      canPop: blocked == null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (blocked == null)
            child
          else
            Container(color: context.dr.bgSurface),
          if (blocked != null) ...[
            const ModalBarrier(dismissible: false, color: Colors.black54),
            Center(child: _BlockedCard(childName: blocked.fullName)),
          ],
        ],
      ),
    );
  }
}

class _BlockedCard extends StatefulWidget {
  final String childName;
  const _BlockedCard({required this.childName});

  @override
  State<_BlockedCard> createState() => _BlockedCardState();
}

class _BlockedCardState extends State<_BlockedCard> {
  void _openAddChild() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddChildSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.dr.bgSurface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.block_rounded,
              size: 44,
              color: DrColors.redStrong,
            ),
            const SizedBox(height: 14),
            const Text(
              'Diqqət',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              widget.childName.isEmpty
                  ? 'Sizin uşaq bloklanıb.'
                  : '${widget.childName} bloklanıb.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.dr.textMuted, height: 1.4),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _openAddChild,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.dr.bgSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: context.dr.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.dr.accentSoft,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 22,
                        color: context.dr.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.settingsAddChild,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.settingsAddChildSubtitle,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: context.dr.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: context.dr.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
              child: Text(
                'Çıxış',
                style: TextStyle(color: context.dr.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddChildSheet extends StatefulWidget {
  const _AddChildSheet();

  @override
  State<_AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends State<_AddChildSheet> {
  final _admissionController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _admissionController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final admissionNo = _admissionController.text.trim();
    if (admissionNo.isEmpty) {
      setState(() => _error = context.l10n.addChildEnterNumber);
      return;
    }

    setState(() => _error = null);
    context.read<AuthBloc>().add(AuthChildAdded(admissionNo));
  }

  void _onSettled(BuildContext context, AuthState state) {
    final failure = state.addChildError;
    if (failure != null) {
      setState(() => _error = failure);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final addedMessage = context.l10n.addChildAdded;

    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(addedMessage)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
      previous.isAddingChild && !current.isAddingChild,
      listener: _onSettled,
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final submitting = context.select<AuthBloc, bool>(
          (bloc) => bloc.state.isAddingChild,
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.dr.bgSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: context.dr.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.dr.accentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 20,
                        color: context.dr.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.addChildTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: submitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Icon(Icons.close, color: context.dr.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  context.l10n.addChildAnotherText,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: context.dr.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                DrTextField(
                  label: context.l10n.addChildField,
                  hint: context.l10n.addChildHint,
                  icon: Icons.badge_outlined,
                  controller: _admissionController,
                  enabled: !submitting,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 16,
                        color: DrColors.redStrong,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: DrColors.redStrong,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                const _WhereToFindHint(),
                const SizedBox(height: 20),
                DrPrimaryButton(
                  label: context.l10n.addChildSubmit,
                  trailingIcon: Icons.arrow_forward_rounded,
                  loading: submitting,
                  onTap: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WhereToFindHint extends StatelessWidget {
  const _WhereToFindHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.dr.bgSurfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: 16,
                color: context.dr.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.addChildWhereTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final line in [
            context.l10n.addChildWhere1,
            context.l10n.addChildWhere2,
            context.l10n.addChildWhere3,
          ])
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.dr.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      line,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: context.dr.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}