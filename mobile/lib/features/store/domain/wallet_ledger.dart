enum WalletTransactionType { earn, spend, purchase, refund, adjustment }

final class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.reason,
    required this.createdAt,
    this.reference,
  });

  final String id;
  final int amount;
  final WalletTransactionType type;
  final String reason;
  final String? reference;
  final DateTime createdAt;
}

/// Projects server-verified ledger rows. It never writes a balance by itself.
abstract final class WalletLedgerProjection {
  static int balance(Iterable<WalletTransaction> transactions) {
    final ids = <String>{};
    var total = 0;
    for (final transaction in transactions) {
      if (!ids.add(transaction.id)) {
        throw StateError('Duplicate wallet transaction: ${transaction.id}');
      }
      if (transaction.amount == 0) {
        throw StateError('Wallet transactions cannot have a zero amount');
      }
      total += transaction.amount;
      if (total < 0) {
        throw StateError('Ledger would produce a negative balance');
      }
    }
    return total;
  }
}
