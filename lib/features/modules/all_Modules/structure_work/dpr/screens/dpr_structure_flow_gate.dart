import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'dpr_structure_create_screen.dart';

class DprStructureFlowGate extends ConsumerWidget {
  final SiteModel site;
  const DprStructureFlowGate({super.key, required this.site});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Structure work DPR goes directly to the create screen
    return DprStructureCreateScreen(siteId: site.id, siteName: site.siteName);
  }
}
