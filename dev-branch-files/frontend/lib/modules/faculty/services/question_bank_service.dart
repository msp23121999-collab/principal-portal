// ignore_for_file: dangling_library_doc_comments
/// ============================================================
/// QUESTION BANK SERVICE — Supabase Integrated (No Mock Data)
/// ============================================================
library;

import 'package:flutter/foundation.dart';
import 'local_storage_base.dart';
import 'supabase_client.dart';

class QuestionBankService {
  static const String _key = 'questionBank';
  static const String _table = 'question_banks';

  static void seedIfEmpty() {}

  static List<Map<String, dynamic>> getAll() {
    return LocalStorageBase.readList(_key);
  }

  static Future<List<Map<String, dynamic>>> fetchFromSupabase() async {
    try {
      final remote = await SupabaseClientHelper.select(_table);
      if (remote.isNotEmpty) {
        final converted = remote.map((q) => {
          'questionBankId': q['id']?.toString() ?? '',
          'id': q['id']?.toString() ?? '',
          'facultyId': q['faculty_id']?.toString() ?? 'FAC73124',
          'unit': q['unit'] ?? 'Unit 1',
          'difficulty': q['difficulty'] ?? 'MEDIUM',
          'bloom': q['blooms_level'] ?? 'Understand (L2)',
          'type': q['question_type'] ?? 'Part A (2 Marks)',
          'question': q['question_text'] ?? '',
          'marks': (q['marks'] as num? ?? 2).toInt(),
          'co': q['course_outcome'] ?? 'CO1',
          'status': q['status'] ?? 'Draft',
          'submissionStatus': q['submission_status'] ?? 'Draft',
          'rejectionReason': q['rejection_reason'],
          'createdAt': q['created_at'] ?? '',
        }).toList();
        LocalStorageBase.writeList(_key, converted);
        return converted;
      }
    } catch (e) {
      debugPrint('Error fetching questions from Supabase: $e');
    }
    return getAll();
  }

  static void save(Map<String, dynamic> question) {
    final all = getAll();
    if (question['questionBankId'] == null || question['questionBankId'].toString().isEmpty) {
      question['questionBankId'] = LocalStorageBase.generateId('QB');
    }
    question['id'] ??= question['questionBankId'];
    question['createdAt'] ??= DateTime.now().toIso8601String();
    question['status'] ??= 'Draft';
    
    final idx = all.indexWhere((q) => q['questionBankId'] == question['questionBankId']);
    if (idx >= 0) {
      all[idx] = question;
    } else {
      all.add(question);
    }
    LocalStorageBase.writeList(_key, all);

    SupabaseClientHelper.upsert(_table, {
      'question_bank_id': question['questionBankId'],
      'faculty_id': question['facultyId'] ?? 'FAC73124',
      'subject': question['subject'] ?? '',
      'unit': question['unit'] ?? 'Unit 1',
      'difficulty': question['difficulty'] ?? 'MEDIUM',
      'blooms_level': question['bloom'] ?? 'Remember (L1)',
      'question_type': question['type'] ?? 'Part A (2 Marks)',
      'question_text': question['question'] ?? '',
      'marks': question['marks'] ?? 2,
      'course_outcome': question['co'] ?? 'CO1',
      'status': question['status'] ?? 'Draft',
    }, 'question_bank_id');
  }

  static void updateBankStatus({String? subject, String status = 'Pending HOD Review'}) {
    final all = getAll();
    for (final q in all) {
      if (subject == null || q['subject'] == subject) {
        q['status'] = status;
        q['submissionStatus'] = status;
      }
    }
    LocalStorageBase.writeList(_key, all);
  }

  static void delete(String questionBankId) {
    final all = getAll();
    all.removeWhere((q) => q['questionBankId'] == questionBankId || q['id'] == questionBankId);
    LocalStorageBase.writeList(_key, all);

    SupabaseClientHelper.delete(_table, 'question_bank_id', questionBankId);
  }
}
