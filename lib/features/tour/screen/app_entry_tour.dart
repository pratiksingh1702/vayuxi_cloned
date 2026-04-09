import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/tour_controller.dart';
import '../registry/site_registry.dart';

class AppTourEntryTile extends ConsumerWidget {
  const AppTourEntryTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.assistant, color: Colors.blue),
      title: const Text("App Tour"),
      subtitle: const Text("Replay Buddy guided tour"),
      onTap: () async {
        await ref
            .read(tourControllerProvider.notifier)
            .replayModule(SiteRegistry.module);
        if (context.mounted) {
          context.go('/select-module?index=1');
        }
      },
    );
  }
}
