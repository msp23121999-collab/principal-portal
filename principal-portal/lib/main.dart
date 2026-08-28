import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/api_client.dart';

class _DebugObserver extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      debugPrint(
        'Provider error in [${provider.name ?? provider.runtimeType}]: '
        '$error\n$stackTrace',
      );
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.initialise();
  runApp(
    ProviderScope(
      observers: [_DebugObserver()],
      child: const PrincipalPortalApp(),
    ),
  );
}

