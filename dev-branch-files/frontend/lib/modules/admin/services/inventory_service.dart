import '../models/inventory_model.dart';
import '../../../shared/services/supabase_service.dart';

class InventoryService {
  static Future<List<InventoryModel>> fetchInventory() async {
    try {
      final data = await SupabaseService.instance.fetchTable(
        'inventory_assets',
      );
      return data.map((row) => InventoryModel.fromJson(row)).toList();
    } catch (e) {
      print('Error fetching inventory assets: $e');
      return [];
    }
  }

  static Future<InventoryModel?> addInventory(InventoryModel item) async {
    try {
      final inserted = await SupabaseService.instance.insertData(
        'inventory_assets',
        item.toJson(),
      );
      if (inserted != null) {
        return InventoryModel.fromJson(inserted);
      }
    } catch (e) {
      print('Error adding inventory asset: $e');
    }
    return null;
  }
}
