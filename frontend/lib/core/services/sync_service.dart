import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';

class SyncService {
  static const String baseUrl = 'http://192.168.100.144:6000/api';
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Sync crops from server to local database
  Future<bool> syncCropsFromServer() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/crops'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final crops = List<Map<String, dynamic>>.from(data['data']);
        
        // Clear existing crops and insert new ones
        await _dbHelper.bulkInsertCrops(crops);
        return true;
      }
      return false;
    } catch (e) {
      print('Error syncing crops from server: $e');
      return false;
    }
  }

  // Sync farmers from server to local database
  Future<bool> syncFarmersFromServer() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/farmers'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final farmers = List<Map<String, dynamic>>.from(data['data']);
        
        await _dbHelper.bulkInsertFarmers(farmers);
        return true;
      }
      return false;
    } catch (e) {
      print('Error syncing farmers from server: $e');
      return false;
    }
  }

  // Sync local changes to server
  Future<bool> syncLocalChangesToServer() async {
    try {
      final unsyncedItems = await _dbHelper.getUnsyncedItems();
      
      for (var item in unsyncedItems) {
        final tableName = item['table_name'];
        final action = item['action'];
        final recordId = item['record_id'];
        final data = item['data'];
        
        bool success = false;
        
        switch (tableName) {
          case 'crops':
            success = await _syncCropToServer(action, recordId, data);
            break;
          case 'farmers':
            success = await _syncFarmerToServer(action, recordId, data);
            break;
          case 'orders':
            success = await _syncOrderToServer(action, recordId, data);
            break;
        }
        
        if (success) {
          await _dbHelper.markSyncQueueItemAsSynced(item['id']);
          await _dbHelper.markAsSynced(tableName, recordId);
        }
      }
      
      return true;
    } catch (e) {
      print('Error syncing local changes to server: $e');
      return false;
    }
  }

  Future<bool> _syncCropToServer(String action, String recordId, String data) async {
    try {
      switch (action) {
        case 'INSERT':
          final response = await http.post(
            Uri.parse('$baseUrl/crops'),
            headers: {'Content-Type': 'application/json'},
            body: data,
          );
          return response.statusCode == 201;
          
        case 'UPDATE':
          final response = await http.put(
            Uri.parse('$baseUrl/crops/$recordId'),
            headers: {'Content-Type': 'application/json'},
            body: data,
          );
          return response.statusCode == 200;
          
        case 'DELETE':
          final response = await http.delete(Uri.parse('$baseUrl/crops/$recordId'));
          return response.statusCode == 200;
          
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> _syncFarmerToServer(String action, String recordId, String data) async {
    try {
      switch (action) {
        case 'INSERT':
          final response = await http.post(
            Uri.parse('$baseUrl/farmers'),
            headers: {'Content-Type': 'application/json'},
            body: data,
          );
          return response.statusCode == 201;
          
        case 'UPDATE':
          final response = await http.put(
            Uri.parse('$baseUrl/farmers/$recordId'),
            headers: {'Content-Type': 'application/json'},
            body: data,
          );
          return response.statusCode == 200;
          
        case 'DELETE':
          final response = await http.delete(Uri.parse('$baseUrl/farmers/$recordId'));
          return response.statusCode == 200;
          
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> _syncOrderToServer(String action, String recordId, String data) async {
    try {
      switch (action) {
        case 'INSERT':
          final response = await http.post(
            Uri.parse('$baseUrl/orders'),
            headers: {'Content-Type': 'application/json'},
            body: data,
          );
          return response.statusCode == 201;
          
        case 'UPDATE':
          final response = await http.put(
            Uri.parse('$baseUrl/orders/$recordId'),
            headers: {'Content-Type': 'application/json'},
            body: data,
          );
          return response.statusCode == 200;
          
        case 'DELETE':
          final response = await http.delete(Uri.parse('$baseUrl/orders/$recordId'));
          return response.statusCode == 200;
          
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Check network connectivity and sync
  Future<bool> performFullSync() async {
    try {
      // First, sync data from server
      final cropsSync = await syncCropsFromServer();
      final farmersSync = await syncFarmersFromServer();
      
      // Then, sync local changes to server
      final localSync = await syncLocalChangesToServer();
      
      return cropsSync && farmersSync && localSync;
    } catch (e) {
      print('Error performing full sync: $e');
      return false;
    }
  }

  // Check if device is online
  Future<bool> isOnline() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health')).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
