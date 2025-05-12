// This file is the actual implementation of web storage using idb_shim
// It will only be used when compiling for web platforms

import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb_shim.dart';
import 'package:idb_shim/idb_browser.dart';
import 'storage_interface.dart';

/// Implementation of storage for web platforms using IndexedDB via idb_shim
@pragma('dart2js:preferInline')
class StorageImplementationWeb implements StorageInterface {
  static const String _dbName = 'assets_differ_db';
  static const String _storeName = 'assets_store';
  static const int _dbVersion = 1;
  Database? _db;
  
  /// Get or initialize the IndexedDB database
  Future<Database> _getDatabase() async {
    if (_db != null) {
      return _db!;
    }
    
    // Get the browser factory
    final idbFactory = getIdbFactory();
    
    // Open the database and create object store if needed
    _db = await idbFactory?.open(_dbName, version: _dbVersion,
      onUpgradeNeeded: (VersionChangeEvent event) {
        final db = event.database;
        // Create an object store if it doesn't exist
        if (!db.objectStoreNames.contains(_storeName)) {
          final store = db.createObjectStore(_storeName, keyPath: 'path');
          // Create an index for faster lookups by path
          store.createIndex('path_idx', 'path', unique: true);
        }
      }
    );
    
    return _db!;
  }
  
  @override
  Future<void> saveAsset(String assetPath, String data) async {
    try {
      final db = await _getDatabase();
      
      // Start a transaction
      final Transaction txn = db.transaction(_storeName, 'readwrite');
      final ObjectStore store = txn.objectStore(_storeName);
      
      // Create asset object
      final Map<String, dynamic> asset = {
        'path': assetPath,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Save the asset
      await store.put(asset);
      
      // Complete the transaction
      await txn.completed;
      
      print('Asset saved to IndexedDB (web): $assetPath');
    } catch (e) {
      print('Error saving asset to IndexedDB: $e');
      rethrow;
    }
  }
  
  @override
  Future<String> getAsset(String assetPath) async {
    try {
      final db = await _getDatabase();
      
      // Start a transaction
      final Transaction txn = db.transaction(_storeName, 'readonly');
      final ObjectStore store = txn.objectStore(_storeName);
      
      // Find asset by path
      final dynamic rawAsset = await store.getObject(assetPath);
      
      // Complete the transaction
      await txn.completed;
      
      if (rawAsset != null) {
        // Safely convert LinkedMap to Map<String, dynamic>
        final Map<String, dynamic> asset = Map<String, dynamic>.from(rawAsset as Map);
        return asset['data'] as String;
      } else {
        print('Asset not found in IndexedDB: $assetPath');
        return '';
      }
    } catch (e) {
      print('Error retrieving asset from IndexedDB: $e');
      return '';
    }
  }
  
  @override
  Future<bool> deleteAsset(String assetPath) async {
    try {
      final db = await _getDatabase();
      
      // Start a transaction
      final Transaction txn = db.transaction(_storeName, 'readwrite');
      final ObjectStore store = txn.objectStore(_storeName);
      
      // Check if asset exists first
      final dynamic rawAsset = await store.getObject(assetPath);
      
      if (rawAsset != null) {
        // Delete the asset
        await store.delete(assetPath);
        
        // Complete the transaction
        await txn.completed;
        
        print('Asset deleted from IndexedDB: $assetPath');
        return true;
      } else {
        print('Asset not found in IndexedDB for deletion: $assetPath');
        await txn.completed;
        return false;
      }
    } catch (e) {
      print('Error deleting asset from IndexedDB: $e');
      return false;
    }
  }
  
  @override
  Future<void> close() async {
    if (_db != null) {
      _db!.close();
      _db = null;
    }
  }
  
}