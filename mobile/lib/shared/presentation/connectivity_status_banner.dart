import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// A compact live-region banner for screens that depend on a real-time link.
///
/// Network availability does not guarantee internet reachability, so gameplay
/// requests continue to own their retry/error handling. This widget only gives
/// the player immediate, calm feedback when the device loses or regains a
/// network interface.
final class ConnectivityStatusBanner extends StatefulWidget {
  const ConnectivityStatusBanner({super.key});

  @override
  State<ConnectivityStatusBanner> createState() =>
      _ConnectivityStatusBannerState();
}

final class _ConnectivityStatusBannerState
    extends State<ConnectivityStatusBanner> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _restoredTimer;
  bool _offline = false;
  bool _showRestored = false;
  bool _hasInitialState = false;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  Future<void> _listen() async {
    try {
      _handle(await Connectivity().checkConnectivity());
      _subscription = Connectivity().onConnectivityChanged.listen(
        _handle,
        onError: (_) {},
      );
    } catch (_) {
      // Some widget/unit test environments do not register platform plugins.
      // Gameplay request errors remain the authoritative fallback there.
    }
  }

  void _handle(List<ConnectivityResult> results) {
    if (!mounted) return;
    final isOffline =
        results.isEmpty ||
        results.every((item) => item == ConnectivityResult.none);
    final wasOffline = _hasInitialState && _offline;
    _restoredTimer?.cancel();
    setState(() {
      _offline = isOffline;
      _showRestored = wasOffline && !isOffline;
      _hasInitialState = true;
    });
    if (_showRestored) {
      _restoredTimer = Timer(AppMotion.connectivityNotice, () {
        if (mounted) setState(() => _showRestored = false);
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _restoredTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _offline || _showRestored;
    final colors = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final background = _offline
        ? colors.errorContainer
        : context.ahdashColors.success.withValues(alpha: 0.16);
    final foreground = _offline
        ? colors.onErrorContainer
        : context.ahdashColors.success;

    return Semantics(
      liveRegion: true,
      label: visible
          ? (_offline ? 'انقطع الاتصال. جاري إعادة الاتصال' : 'عاد الاتصال')
          : null,
      child: ClipRect(
        child: AnimatedAlign(
          duration: reduceMotion ? Duration.zero : AppMotion.fast,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          heightFactor: visible ? 1 : 0,
          child: AnimatedOpacity(
            duration: reduceMotion ? Duration.zero : AppMotion.fast,
            opacity: visible ? 1 : 0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              color: background,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _offline
                        ? Icons.cloud_off_rounded
                        : Icons.cloud_done_rounded,
                    size: 18,
                    color: foreground,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      _offline ? 'جاري إعادة الاتصال…' : 'رجع الاتصال',
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
