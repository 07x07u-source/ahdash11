import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/presentation/app_states.dart';
import '../../../shared/presentation/brand_identity.dart';
import '../../../shared/presentation/brand_scaffold.dart';
import '../../../shared/presentation/currency_widgets.dart';
import '../../../shared/presentation/game_ui.dart';
import '../../../shared/presentation/landscape_layout.dart';
import '../../profile/presentation/profile_controller.dart';

final class WalletEntry {
  const WalletEntry({
    required this.id,
    required this.amount,
    required this.balanceAfter,
    required this.type,
    required this.reason,
    required this.createdAt,
  });

  factory WalletEntry.fromJson(Map<String, Object?> json) => WalletEntry(
    id: '${json['id']}',
    amount: (json['amount'] as num?)?.round() ?? 0,
    balanceAfter: (json['balance_after'] as num?)?.round() ?? 0,
    type: '${json['type'] ?? ''}',
    reason: '${json['reason'] ?? ''}',
    createdAt: DateTime.tryParse('${json['created_at'] ?? ''}')?.toLocal(),
  );

  final String id;
  final int amount;
  final int balanceAfter;
  final String type;
  final String reason;
  final DateTime? createdAt;
}

final walletHistoryProvider = FutureProvider<List<WalletEntry>>((ref) async {
  final config = ref.watch(appConfigProvider);
  if (!config.hasSupabase ||
      Supabase.instance.client.auth.currentUser == null) {
    return const [];
  }
  final rows = await Supabase.instance.client
      .from('wallet_transactions')
      .select(
        'id,amount,balance_after,type,reason,created_at,wallets!inner(user_id)',
      )
      .eq('wallets.user_id', Supabase.instance.client.auth.currentUser!.id)
      .order('created_at', ascending: false)
      .limit(60);
  return rows
      .whereType<Map<String, Object?>>()
      .map(WalletEntry.fromJson)
      .toList(growable: false);
});

final class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerProfileProvider);
    final entries = ref.watch(walletHistoryProvider);
    final balance = profile.value?.coins ?? 0;
    final metrics = LandscapeMetrics.of(context);
    return BrandScaffold(
      appBar: AppBar(
        title: const Text('محفظة أحدعش'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: () {
              ref.invalidate(playerProfileProvider);
              ref.invalidate(walletHistoryProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: AhdashGameWorld(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(metrics.gutter),
            child: AccessibilityViewport(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 4, child: _BalancePanel(balance: balance)),
                  SizedBox(width: metrics.panelGap),
                  Expanded(
                    flex: 7,
                    child: GamePanel(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const CompactSectionTitle(
                            eyebrow: 'كل حركة معتمدة من الخادم',
                            title: 'سجل المحفظة',
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Expanded(
                            child: entries.when(
                              loading: () =>
                                  const Center(child: ElevenLoader()),
                              error: (_, _) => AppMessageState(
                                icon: Icons.account_balance_wallet_outlined,
                                title: 'تعذر تحميل السجل',
                                message: 'رصيدك محفوظ. حاول مجددًا.',
                                actionLabel: 'إعادة المحاولة',
                                onAction: () =>
                                    ref.invalidate(walletHistoryProvider),
                              ),
                              data: (values) => GamePagedList<WalletEntry>(
                                items: values,
                                pageSize: 4,
                                aspectRatio: 5.2,
                                empty: const AppMessageState(
                                  icon: Icons.receipt_long_outlined,
                                  title: 'لا حركات حتى الآن',
                                  message: 'مكافآتك ومشترياتك ستظهر هنا بوضوح.',
                                ),
                                itemBuilder: (_, entry, _) =>
                                    _WalletRow(entry: entry),
                              ),
                            ),
                          ),
                        ],
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

final class _BalancePanel extends StatelessWidget {
  const _BalancePanel({required this.balance});
  final int balance;

  @override
  Widget build(BuildContext context) => GamePanel(
    tone: GameSurfaceTone.gold,
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            AhdashBrandLogo.mark(height: 38),
            Spacer(),
            Text(
              'WALLET',
              textDirection: TextDirection.ltr,
              style: TextStyle(fontSize: 9),
            ),
          ],
        ),
        const Spacer(),
        const Center(
          child: AhdashCoinIcon(size: 78, semanticLabel: 'كوين أحدعش'),
        ),
        const Spacer(),
        const Text('رصيدك الحالي'),
        const SizedBox(height: AppSpacing.xs),
        AhdashCoinBalance(balance: balance),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'لا توجد نقاط وهمية؛ الرصيد يأتي من الخادم.',
          style: TextStyle(color: context.ahdashColors.textMuted),
        ),
      ],
    ),
  );
}

final class _WalletRow extends StatelessWidget {
  const _WalletRow({required this.entry});
  final WalletEntry entry;

  @override
  Widget build(BuildContext context) {
    final incoming = entry.amount > 0;
    return GamePanel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          const AhdashCoinIcon(size: 34, semanticLabel: 'كوين أحدعش'),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label(entry.reason),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  _date(entry.createdAt),
                  style: const TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${incoming ? '+' : ''}${entry.amount}',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: incoming
                      ? context.ahdashColors.primary
                      : context.ahdashColors.gold,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'الرصيد ${entry.balanceAfter}',
                style: const TextStyle(fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _label(String reason) => switch (reason) {
    'store_purchase' => 'شراء من المتجر',
    'match_reward' => 'مكافأة مباراة',
    'rewarded_ad' => 'مكافأة إعلان',
    'daily_reward' => 'مكافأة يومية',
    _ => 'حركة محفظة',
  };

  String _date(DateTime? value) {
    if (value == null) return '';
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}/${value.month}/${value.day} • ${value.hour}:$minute';
  }
}
