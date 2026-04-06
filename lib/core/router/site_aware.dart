// core/router/site_aware_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';

class SiteAwareWrapper extends ConsumerStatefulWidget {
  final SiteModel site;
  final Widget child;

  const SiteAwareWrapper({
    super.key,
    required this.site,
    required this.child,
  });

  @override
  ConsumerState<SiteAwareWrapper> createState() => _SiteAwareWrapperState();
}

class _SiteAwareWrapperState extends ConsumerState<SiteAwareWrapper> {
  @override
  void initState() {
    super.initState();
    // ✅ Safe — after the frame is done building
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(selectedSiteIdProvider.notifier).state = widget.site.id;
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}