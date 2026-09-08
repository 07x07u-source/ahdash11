import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_config.dart';
import '../../profile/presentation/profile_controller.dart';
import '../domain/launch_catalog.dart';
import '../domain/store_item.dart';

final class StorefrontCatalog {
  const StorefrontCatalog({required this.items, required this.remoteBacked});

  final List<StoreItem> items;
  final bool remoteBacked;

  List<StoreItem> get featured =>
      items.where((item) => item.isFeatured).toList(growable: false);

  List<StoreItem> get newItems =>
      items.where((item) => item.isNew).toList(growable: false);

  List<StoreItem> get owned =>
      items.where((item) => item.isOwned).toList(growable: false);
}

final storeCatalogProvider = FutureProvider<StorefrontCatalog>((ref) async {
  final config = ref.watch(appConfigProvider);
  if (!config.hasSupabase) {
    return StorefrontCatalog(
      items: LaunchStoreCatalog.items,
      remoteBacked: false,
    );
  }
  try {
    final client = Supabase.instance.client;
    final itemRows = await client
        .from('store_items')
        .select(
          'id,sku,name_ar,description_ar,type,image_url,price_coins,metadata,'
          'sort_order,is_active,created_at',
        )
        .eq('is_active', true)
        .eq('type', 'cosmetic')
        .not('price_coins', 'is', null)
        .order('sort_order');
    final inventoryRows = client.auth.currentUser == null
        ? const <Map<String, Object?>>[]
        : await client
              .from('user_inventory')
              .select('store_item_id,status,equipped_at')
              .eq('status', 'active');
    final inventory = <String, Map<String, Object?>>{
      for (final row in inventoryRows.whereType<Map<String, Object?>>())
        '${row['store_item_id']}': row,
    };
    final parsed = itemRows
        .whereType<Map<String, Object?>>()
        .map((row) {
          final item = StoreItem.fromJson(row);
          final owned = inventory[item.id];
          return item.copyWith(
            isOwned: owned != null,
            isEquipped: owned?['equipped_at'] != null,
          );
        })
        .where((item) => item.isCosmetic)
        .toList(growable: false);
    return StorefrontCatalog(
      items: parsed.isEmpty ? LaunchStoreCatalog.items : parsed,
      remoteBacked: parsed.isNotEmpty,
    );
  } catch (_) {
    return StorefrontCatalog(
      items: LaunchStoreCatalog.items,
      remoteBacked: false,
    );
  }
});

enum StoreActionStatus {
  idle,
  purchasing,
  equipping,
  success,
  insufficientCoins,
  alreadyOwned,
  unavailable,
  offline,
  error,
}

final class StoreActionState {
  const StoreActionState({
    this.status = StoreActionStatus.idle,
    this.item,
    this.message,
    this.newBalance,
    this.transactionId,
    this.canRetry = false,
  });

  final StoreActionStatus status;
  final StoreItem? item;
  final String? message;
  final int? newBalance;
  final String? transactionId;
  final bool canRetry;

  bool get isBusy =>
      status == StoreActionStatus.purchasing ||
      status == StoreActionStatus.equipping;
}

final storeActionProvider =
    NotifierProvider<StoreActionController, StoreActionState>(
      StoreActionController.new,
    );

final class StoreActionController extends Notifier<StoreActionState> {
  String? _pendingIdempotencyKey;
  StoreItem? _pendingItem;
  bool _pendingEquip = false;
  int _clientSequence = 0;

  @override
  StoreActionState build() => const StoreActionState();

  Future<void> purchase(StoreItem item) async {
    if (state.isBusy) return;
    _pendingItem = item;
    _pendingEquip = false;
    _pendingIdempotencyKey ??= const Uuid().v4();
    await _submit(item: item, equip: false);
  }

  Future<void> equip(StoreItem item) async {
    if (state.isBusy) return;
    _pendingItem = item;
    _pendingEquip = true;
    _pendingIdempotencyKey = const Uuid().v4();
    await _submit(item: item, equip: true);
  }

  Future<void> retry() async {
    final item = _pendingItem;
    if (item == null || state.isBusy) return;
    await _submit(item: item, equip: _pendingEquip);
  }

  void clear() {
    state = const StoreActionState();
  }

  Future<void> _submit({required StoreItem item, required bool equip}) async {
    final config = ref.read(appConfigProvider);
    if (!config.hasSupabase ||
        Supabase.instance.client.auth.currentUser == null) {
      state = StoreActionState(
        status: StoreActionStatus.unavailable,
        item: item,
        message: 'سجّل الدخول واتصل بالخادم لإكمال العملية.',
      );
      return;
    }
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.isEmpty ||
          connectivity.every((value) => value == ConnectivityResult.none)) {
        state = StoreActionState(
          status: StoreActionStatus.offline,
          item: item,
          message: 'الشراء والتجهيز يحتاجان اتصالًا بالخادم.',
          canRetry: true,
        );
        return;
      }
    } catch (_) {
      // The authenticated server request remains the authoritative reachability check.
    }
    state = StoreActionState(
      status: equip
          ? StoreActionStatus.equipping
          : StoreActionStatus.purchasing,
      item: item,
    );
    try {
      final key = _pendingIdempotencyKey ??= const Uuid().v4();
      final response = await Supabase.instance.client.functions.invoke(
        'wallet-transaction',
        body: {
          'action': equip ? 'equip' : 'purchase',
          'storeItemId': item.id,
          'idempotencyKey': key,
          'clientSequence': ++_clientSequence,
        },
      );
      final data = response.data is Map<Object?, Object?>
          ? Map<String, Object?>.from(response.data! as Map<Object?, Object?>)
          : const <String, Object?>{};
      final status = '${data['status'] ?? 'success'}';
      final rawBalance = data['new_balance'] ?? data['balance'];
      final mappedStatus = switch (status) {
        'already_owned' => StoreActionStatus.alreadyOwned,
        'insufficient_coins' => StoreActionStatus.insufficientCoins,
        'unavailable' => StoreActionStatus.unavailable,
        _ => StoreActionStatus.success,
      };
      state = StoreActionState(
        status: mappedStatus,
        item: item,
        message: mappedStatus == StoreActionStatus.insufficientCoins
            ? 'رصيدك ما يكفي لهذا العنصر.'
            : equip
            ? 'صار مستخدمًا الحين.'
            : 'تمت الإضافة لمقتنياتك.',
        newBalance: rawBalance is num ? rawBalance.round() : null,
        transactionId: data['transaction_id'] as String?,
      );
      if (mappedStatus != StoreActionStatus.insufficientCoins) {
        _pendingIdempotencyKey = null;
        _pendingItem = null;
      }
      ref.invalidate(storeCatalogProvider);
      ref.invalidate(playerProfileProvider);
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('insufficient')) {
        state = StoreActionState(
          status: StoreActionStatus.insufficientCoins,
          item: item,
          message: 'رصيدك ما يكفي لهذا العنصر.',
        );
      } else if (message.contains('already_owned')) {
        state = StoreActionState(
          status: StoreActionStatus.alreadyOwned,
          item: item,
          message: 'العنصر صار لك من قبل.',
        );
      } else {
        state = StoreActionState(
          status: StoreActionStatus.error,
          item: item,
          message: 'ما وصلنا تأكيد العملية. جرّب إعادة آمنة بنفس الطلب.',
          canRetry: true,
        );
      }
    }
  }
}
