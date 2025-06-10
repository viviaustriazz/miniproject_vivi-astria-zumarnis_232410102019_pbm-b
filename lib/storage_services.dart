import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'hasil_scan_qr.dart';

class StorageService {
  static const String _keyPrefix = 'scan_results';

  static Future<List<ScanResult>> getScanResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> jsonStrings = prefs.getStringList(_keyPrefix) ?? [];
      
      return jsonStrings
          .map((jsonString) => ScanResult.fromJson(json.decode(jsonString)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveScanResult(ScanResult result) async {
    List<ScanResult> results = await getScanResults();
    results.insert(0, result); // Insert at beginning
    
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonStrings = results
        .map((result) => json.encode(result.toJson()))
        .toList();
    
    await prefs.setStringList(_keyPrefix, jsonStrings);
  }

  static Future<void> clearScanResults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPrefix);
  }
}