import 'package:flutter/material.dart';

import '../../../../../../core/api/dio.dart';
import '../../../boq/service/boq_service.dart';
import '../add_description.dart';
import 'mechanichal_stepper.dart';

class MechanicalDprEntryGate extends StatefulWidget {
  const MechanicalDprEntryGate({
    super.key,
    this.siteId,
    this.teamId,
    this.teamName,
  });

  final String? siteId;
  final String? teamId;
  final String? teamName;

  @override
  State<MechanicalDprEntryGate> createState() => _MechanicalDprEntryGateState();
}

class _MechanicalDprEntryGateState extends State<MechanicalDprEntryGate> {
  late final Future<bool> _hasMechanicalBoqFuture;

  @override
  void initState() {
    super.initState();
    _hasMechanicalBoqFuture = _hasMechanicalBoq();
  }

  Future<bool> _hasMechanicalBoq() async {
    final siteId = widget.siteId?.trim();
    if (siteId == null || siteId.isEmpty) return false;

    try {
      final boqs = await BoqApiService(
        DioClient.dio,
      ).getMechanicalPipingBoqs(siteId: siteId);
      return boqs.isNotEmpty;
    } catch (e) {
      debugPrint('Mechanical BOQ gate check failed: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasMechanicalBoqFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return AddDescriptionScreen(
            siteId: widget.siteId,
            teamId: widget.teamId,
          );
        }

        return MechanichalStepperScreen(
          siteId: widget.siteId,
          teamId: widget.teamId,
          teamName: widget.teamName,
        );
      },
    );
  }
}
