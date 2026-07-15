import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';

/// Balance is persisted locally so it survives app restarts and is shared
/// (single source of truth) between the Balance and Buffet features.
abstract class BalanceLocalDataSource {
  Future<double> getBalance();
  Future<double> addBalance(double amount);
  Future<double> deduct(double amount);
}

class BalanceLocalDataSourceImpl implements BalanceLocalDataSource {
  static const _key = 'user_balance';
  static const _initial = 25.0;

  final SharedPreferences prefs;
  const BalanceLocalDataSourceImpl(this.prefs);

  @override
  Future<double> getBalance() async {
    return prefs.getDouble(_key) ?? _initial;
  }

  @override
  Future<double> addBalance(double amount) async {
    final next = (await getBalance()) + amount;
    final ok = await prefs.setDouble(_key, next);
    if (!ok) throw const CacheException('Balans yenilənmədi');
    return next;
  }

  @override
  Future<double> deduct(double amount) async {
    final current = await getBalance();
    if (amount > current) {
      throw const ValidationException('Balans kifayət etmir');
    }
    final next = current - amount;
    final ok = await prefs.setDouble(_key, next);
    if (!ok) throw const CacheException('Balans yenilənmədi');
    return next;
  }
}
