import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/dprModel.dart';

class DprDraftRecord {
  final String draftId;
  final DprModel draft;
  final Map<String, dynamic> updateData;
  final String siteId;
  final String teamId;
  final String? mechanicalId;
  final DateTime savedAt;
  final DateTime expiresAt;

  const DprDraftRecord({
    required this.draftId,
    required this.draft,
    required this.updateData,
    required this.siteId,
    required this.teamId,
    required this.savedAt,
    required this.expiresAt,
    this.mechanicalId,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() {
    return {
      'draftId': draftId,
      'draft': draft.toJson(),
      'updateData': updateData,
      'siteId': siteId,
      'teamId': teamId,
      'mechanicalId': mechanicalId,
      'savedAt': savedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory DprDraftRecord.fromJson(Map<String, dynamic> json) {
    return DprDraftRecord(
      draftId: (json['draftId'] ?? '').toString(),
      draft: DprModel.fromJson(Map<String, dynamic>.from(json['draft'] ?? {})),
      updateData: Map<String, dynamic>.from(json['updateData'] ?? {}),
      siteId: (json['siteId'] ?? '').toString(),
      teamId: (json['teamId'] ?? '').toString(),
      mechanicalId: json['mechanicalId']?.toString(),
      savedAt: DateTime.tryParse((json['savedAt'] ?? '').toString()) ??
          DateTime.now(),
      expiresAt: DateTime.tryParse((json['expiresAt'] ?? '').toString()) ??
          DateTime.now().add(const Duration(hours: 24)),
    );
  }
}

class DprDraftRepo {
  static const String _keyPrefix = 'dpr_draft_';

  static String _key(String draftId) => '$_keyPrefix$draftId';

  Future<void> saveDraft(DprDraftRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(record.draftId), jsonEncode(record.toJson()));
  }

  Future<DprDraftRecord?> getDraft(String draftId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(draftId));
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final record = DprDraftRecord.fromJson(decoded);

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

  Future<void> clearExpiredDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix));

    for (final key in keys) {
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) {
        await prefs.remove(key);
        continue;
      }

      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) {
          await prefs.remove(key);
          continue;
        }

        final record = DprDraftRecord.fromJson(decoded);
        if (record.isExpired) {
          await prefs.remove(key);
        }
      } catch (_) {
        await prefs.remove(key);
      }
    }
  }

  Future<Set<DateTime>> getDraftDates({
    required String siteId,
    required String teamId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
    final Set<DateTime> dates = {};

    for (final key in keys) {
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        final record = DprDraftRecord.fromJson(decoded);
        if (record.siteId == siteId &&
            record.teamId == teamId &&
            !record.isExpired) {
          final d = record.draft.date;
          dates.add(DateTime(d.year, d.month, d.day));
        }
      } catch (_) {}
    }
    return dates;
  }

  Future<List<DprDraftRecord>> getAllDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
    final List<DprDraftRecord> drafts = [];

    for (final key in keys) {
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        final record = DprDraftRecord.fromJson(decoded);
        if (!record.isExpired) {
          drafts.add(record);
        }
      } catch (_) {}
    }
    drafts.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return drafts;
  }

  Future<void> clearAllDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
