import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network_mode.dart';

class NetworkModeBanner extends ConsumerWidget {
  const NetworkModeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(networkModeProvider);
    final isVisible =
        state.mode == NetworkMode.suggestedOffline || state.showOfflineBanner;
    final colorScheme = Theme.of(context).colorScheme;

    if (!isVisible) return const SizedBox.shrink();

    final isSuggested = state.mode == NetworkMode.suggestedOffline;
    final message = isSuggested
        ? 'Network is unstable. Switch to offline mode?'
        : 'Offline mode enabled.';

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Container(
            key: ValueKey(state.mode),
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.inverseSurface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isSuggested ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: colorScheme.onInverseSurface,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: colorScheme.onInverseSurface,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSuggested) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      ref.read(networkModeProvider.notifier).switchToOffline(
                            reason: 'User enabled offline mode',
                          );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onInverseSurface,
                    ),
                    child: const Text('Switch'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
