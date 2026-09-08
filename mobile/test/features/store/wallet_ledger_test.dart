import 'package:ahdash_11/features/store/domain/wallet_ledger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WalletTransaction transaction(String id, int amount) => WalletTransaction(
    id: id,
    amount: amount,
    type: amount > 0 ? WalletTransactionType.earn : WalletTransactionType.spend,
    reason: 'test',
    createdAt: DateTime(2026),
  );

  test('projects balance from immutable ledger rows', () {
    final balance = WalletLedgerProjection.balance([
      transaction('a', 100),
      transaction('b', -40),
      transaction('c', 15),
    ]);
    expect(balance, 75);
  });

  test('rejects duplicate transaction ids', () {
    expect(
      () => WalletLedgerProjection.balance([
        transaction('same', 100),
        transaction('same', 20),
      ]),
      throwsStateError,
    );
  });

  test('rejects an overdrawn projection', () {
    expect(
      () => WalletLedgerProjection.balance([transaction('a', -1)]),
      throwsStateError,
    );
  });
}
