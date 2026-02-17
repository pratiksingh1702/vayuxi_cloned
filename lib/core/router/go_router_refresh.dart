import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../features/auth/provider/auth_provider.dart';
import '../../features/pricing/providers/razorpay_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_access.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription _sub;

  GoRouterRefreshStream(Stream stream) {
    _sub = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
final routerRefreshProvider = Provider<ChangeNotifier>((ref) {
  final notifier = ValueNotifier<int>(0);

  ref.listen<AppAccessState>(appAccessProvider, (_, __) {
    print("ROUTER REFRESH");
    notifier.value++;
  });

  return notifier;
});
