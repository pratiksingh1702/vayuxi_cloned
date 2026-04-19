import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../model/dpr_model_insu.dart';

class InsuDprDraftRecord {
  final String draftId;
  final InsulationDprModel draft;
  final Map<String, dynamic> updateData;
  final String siteId;
  final String teamId;
  final String? insulationId;
  final DateTime savedAt;
  final DateTime expiresAt;

  const InsuDprDraftRecord({
    required this.draftId,
    required this.draft,
    required this.updateData,
    required this.siteId,
    required this.teamId,
    required this.savedAt,
    required this.expiresAt,
    this.insulationId,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() {
    return {
      'draftId': draftId,
      'draft': draft.toJson(),
      'updateData': updateData,
      'siteId': siteId,
      'teamId': teamId,
      'insulationId': insulationId,
      'savedAt': savedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory InsuDprDraftRecord.fromJson(Map<String, dynamic> json) {
    return InsuDprDraftRecord(
      draftId: (json['draftId'] ?? '').toString(),
      draft: InsulationDprModel.fromJson(
        Map<String, dynamic>.from(json['draft'] ?? {}),
      ),
      updateData: Map<String, dynamic>.from(json['updateData'] ?? {}),
      siteId: (json['siteId'] ?? '').toString(),
      teamId: (json['teamId'] ?? '').toString(),
      insulationId: json['insulationId']?.toString(),
      savedAt: DateTime.tryParse((json['savedAt'] ?? '').toString()) ??
          DateTime.now(),
      expiresAt: DateTime.tryParse((json['expiresAt'] ?? '').toString()) ??
          DateTime.now().add(const Duration(hours: 24)),
    );
  }
}

class InsuDprDraftRepo {
  static const String _keyPrefix = 'insu_dpr_draft_';

  static String _key(String draftId) => '$_keyPrefix$draftId';

  Future<void> saveDraft(InsuDprDraftRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(record.draftId), jsonEncode(record.toJson()));
  }

  Future<InsuDprDraftRecord?> getDraft(String draftId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(draftId));
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final record = InsuDprDraftRecord.fromJson(decoded);

      if (record.isExpired) {
        await removeDraft(draftId);
        return null;
      }
      return record;
    } catch (_) {
      await removeDraft(draftId);
      return null;
    }
  }

  Future<void> removeDraft(String draftId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(draftId));
  }
}
