import 'package:flutter/foundation.dart';
import '../shared/services/supabase_service.dart';

class RegulationService {
  static Future<List<Map<String, dynamic>>> fetchRegulations() async {
    try {
      return await SupabaseService.instance.fetchTable('regulations');
    } catch (e) {
      debugPrint('Error fetching regulations: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> fetchRegulationById(
    String regulationId,
  ) async {
    try {
      final regulations = await SupabaseService.instance.fetchTable(
        'regulations',
        filter: 'id.eq.$regulationId',
      );
      return regulations.isNotEmpty ? regulations.first : null;
    } catch (e) {
      debugPrint('Error fetching regulation by ID: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchRegulationsByYear(
    String academicYear,
  ) async {
    try {
      return await SupabaseService.instance.fetchTable(
        'regulations',
        filter: 'academic_year.eq.$academicYear',
      );
    } catch (e) {
      debugPrint('Error fetching regulations for year: $e');
      return [];
    }
  }

  static Future<bool> createRegulation(
    Map<String, dynamic> regulationData,
  ) async {
    try {
      final result = await SupabaseService.instance.insertData(
        'regulations',
        regulationData,
      );
      return result != null;
    } catch (e) {
      debugPrint('Error creating regulation: $e');
      return false;
    }
  }

  static Future<bool> updateRegulation(
    String regulationId,
    Map<String, dynamic> data,
  ) async {
    try {
      return await SupabaseService.instance.updateData(
        'regulations',
        data,
        regulationId,
      );
    } catch (e) {
      debugPrint('Error updating regulation: $e');
      return false;
    }
  }

  static Future<bool> deleteRegulation(String regulationId) async {
    try {
      return await SupabaseService.instance.deleteData(
        'regulations',
        regulationId,
      );
    } catch (e) {
      debugPrint('Error deleting regulation: $e');
      return false;
    }
  }
}
