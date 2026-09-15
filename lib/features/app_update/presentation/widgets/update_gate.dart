import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../dr/theme/dr_colors.dart';
import '../../../../dr/widgets/dr_widgets.dart';
import '../../domain/entities/app_version.dart';
import '../cubit/app_update_cubit.dart';

/// Stands between the app and everyone opening it.
///
/// A build the backend no longer supports gets [_UpdateRequiredScreen] instead
/// of [child] — before the login screen, so a signed-out parent on an old
/// build is stopped just the same. An optional update is offered in a sheet
/// the parent can put off.
///
/// Until the check answers, [child] is what shows: the gate never flashes a
/// wall at someone whose build is fine.
class UpdateGate extends StatefulWidget {
  final Widget child;

  const UpdateGate({super.key, required this.child});

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> with WidgetsBindingObserver {
  /// Keeps a second sheet from stacking on the first — the check runs again
  /// on every resume, and a resume can happen with the sheet still up.
  bool _promptOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // People leave the app open for weeks; without this they would only ever
    // be asked on a cold start.
    if (state == AppLifecycleState.resumed) {
      context.read<AppUpdateCubit>().check();
    }
  }

  Future<void> _openPrompt(AppUpdateState state) async {
    final version = state.version;
    if (_promptOpen || version == null) return;
    _promptOpen = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _UpdatePromptSheet(
        version: version,
        currentVersion: state.currentVersion,
        onUpdate: () => _openStore(sheetContext, version.storeUrl),
        onLater: () {
          Navigator.of(sheetContext).pop();
          context.read<AppUpdateCubit>().postpone();
        },
      ),
    );

    if (mounted) _promptOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppUpdateCubit, AppUpdateState>(
      listenWhen: (prev, curr) => prev.requirement != curr.requirement,
      listener: (context, state) {
        if (state.requirement == UpdateRequirement.recommended) {
          _openPrompt(state);
        }
      },
      buildWhen: (prev, curr) =>
          prev.isBlocking != curr.isBlocking || prev.version != curr.version,
      builder: (context, state) {
        if (!state.isBlocking) return widget.child;
        return _UpdateRequiredScreen(state: state);
      },
    );
  }
}

/// Hands the store listing to the system. Nothing else can install the update:
/// an iOS app cannot update itself, so this link is the whole of the action.
Future<void> _openStore(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  bool launched = false;

  if (uri != null && url.isNotEmpty) {
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
  }

  if (launched || !context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(context.l10n.loginCannotOpen)));
}

/// The wall. No back, no dismiss, one way forward.
class _UpdateRequiredScreen extends StatelessWidget {
  final AppUpdateState state;

  const _UpdateRequiredScreen({required this.state});

  @override
  Widget build(BuildContext context) {
    final version = state.version;

    return PopScope(
      // The whole point: the app is not usable on this build, so leaving the
      // screen would only put the parent back in front of it.
      canPop: false,
      child: Scaffold(
        backgroundColor: context.dr.bgDark,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(30, 40, 30, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      margin: const EdgeInsets.only(bottom: 26),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.dr.accent.withValues(alpha: 0.08),
                        boxShadow: [
                          BoxShadow(
                            color: context.dr.accent.withValues(alpha: 0.2),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.system_update_rounded,
                          size: 42,
                          color: context.dr.accent,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    context.l10n.updateForcedTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: context.dr.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    // The school's own wording when it sent one — it knows why
                    // this release matters better than a generic line does.
                    version?.message ?? context.l10n.updateForcedText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: context.dr.textMuted,
                    ),
                  ),
                  const SizedBox(height: 28),
                  DrPrimaryButton(
                    label: context.l10n.updateNow,
                    trailingIcon: Icons.open_in_new_rounded,
                    onTap: version == null
                        ? null
                        : () => _openStore(context, version.storeUrl),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      // The store copy installs over this one and relaunches,
                      // but a parent who updated from the App Store app comes
                      // back here instead; this is their way through.
                      onPressed: () =>
                          context.read<AppUpdateCubit>().check(),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        foregroundColor: context.dr.textMuted,
                      ),
                      child: Text(
                        context.l10n.commonRetry,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.dr.textMuted,
                        ),
                      ),
                    ),
                  ),
                  if (version != null && state.currentVersion.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        context.l10n.updateVersions(
                          state.currentVersion,
                          version.latestVersion,
                        ),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: context.dr.textMuted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The offer. Same content as the wall, minus the wall.
class _UpdatePromptSheet extends StatelessWidget {
  final AppVersion version;
  final String currentVersion;
  final VoidCallback onUpdate;
  final VoidCallback onLater;

  const _UpdatePromptSheet({
    required this.version,
    required this.currentVersion,
    required this.onUpdate,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.dr.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
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
                      Icons.system_update_rounded,
                      size: 20,
                      color: context.dr.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n.updateAvailableTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                version.message ??
                    context.l10n.updateAvailableText(version.latestVersion),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: context.dr.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              DrPrimaryButton(
                label: context.l10n.updateNow,
                trailingIcon: Icons.open_in_new_rounded,
                onTap: onUpdate,
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: onLater,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    foregroundColor: context.dr.textMuted,
                  ),
                  child: Text(
                    context.l10n.updateLater,
                    style: TextStyle(fontSize: 13, color: context.dr.textMuted),
                  ),
                ),
              ),
              if (currentVersion.isNotEmpty)
                Center(
                  child: Text(
                    context.l10n.updateVersions(
                      currentVersion,
                      version.latestVersion,
                    ),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: context.dr.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
