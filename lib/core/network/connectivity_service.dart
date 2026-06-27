import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class ConnectivityService {
  Stream<bool> get onConnectivityChanged;
  Future<bool> get isOnline;
}

class ConnectivityServiceImpl implements ConnectivityService {
  ConnectivityServiceImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );

  @override
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final connectivityProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityServiceImpl(Connectivity());
});

final isOnlineProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityProvider).onConnectivityChanged;
});
