import 'package:flutter/material.dart';

import '../../domain/models/automated_entry_models.dart';

class ImportSummaryPanel extends StatelessWidget {
  const ImportSummaryPanel({
    super.key,
    required this.state,
    required this.onStart,
    required this.onReset,
  });

  final AutomatedEntryState state;
  final VoidCallback onStart;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final isUploading = state.phase == AutomatedEntryPhase.uploading;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E223D), Color(0xFF1D3C67)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 14),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Batch Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.message?.isNotEmpty == true
                ? state.message!
                : 'Select all three files and configure site bindings to start.',
            style: const TextStyle(
              color: Color(0xFFD2E2FB),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (state.createdSiteId != null) ...[
            const SizedBox(height: 10),
            Text(
              'Created Site ID: ${state.createdSiteId}',
              style: const TextStyle(
                color: Color(0xFFA4C8FF),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isUploading ? null : onStart,
                  icon: isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.rocket_launch_rounded),
                  label:
                      Text(isUploading ? 'Running...' : 'Import All Modules'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: isUploading ? null : onReset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF9CC1FF)),
                ),
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
