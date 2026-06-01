import 'dart:async';
import 'dart:io';

/// Reachability check that performs a real DNS resolution instead of relying
/// on the radio link state, so captive portals and "connected but no route"
/// situations are reported as offline. A lightweight poller exposes changes
/// as a boolean stream (true = reachable) without any platform plugin.
class ConnectivityProbe {
  static const List<String> _hosts = ['cloudflare.com', 'apple.com'];

  Future<bool> isOnline() async {
    for (final host in _hosts) {
      try {
        final res = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 4));
        if (res.isNotEmpty && res.first.rawAddress.isNotEmpty) return true;
      } catch (_) {
        // try next host
      }
    }
    return false;
  }

  /// Emits the reachability state whenever it flips. Polls on a relaxed
  /// cadence to keep battery impact negligible.
  Stream<bool> watch({Duration every = const Duration(seconds: 5)}) async* {
    bool? last;
    while (true) {
      final now = await isOnline();
      if (now != last) {
        last = now;
        yield now;
      }
      await Future.delayed(every);
    }
  }
}
