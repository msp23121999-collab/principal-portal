import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get download URL from Firebase Storage
  static Future<String> getDownloadUrl(String storagePath) async {
    try {
      return await _storage.ref(storagePath).getDownloadURL();
    } catch (e) {
      print('Error getting download URL for path: $storagePath');
      print('Error details: $e');
      rethrow;
    }
  }

  /// Upload file to Firebase Storage
  static Future<String> uploadFile(String path, List<int> fileBytes) async {
    try {
      final ref = _storage.ref(path);
      await ref.putData(Uint8List.fromList(fileBytes));
      return await ref.getDownloadURL();
    } catch (e) {
      print('Upload error: $e');
      rethrow;
    }
  }

  /// Get document from Firestore
  static Future<Map<String, dynamic>?> getDocument(
    String collection,
    String docId,
  ) async {
    try {
      final doc = await _firestore.collection(collection).doc(docId).get();
      return doc.data();
    } catch (e) {
      print('Firestore error: $e');
      return null;
    }
  }

  /// Get all documents from collection
  static Future<List<Map<String, dynamic>>> getCollection(
    String collection,
  ) async {
    try {
      final snapshot = await _firestore.collection(collection).get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Collection error: $e');
      return [];
    }
  }

  /// Delete file from Firebase Storage
  static Future<bool> deleteFile(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
      return true;
    } catch (e) {
      print('Delete error: $e');
      return false;
    }
  }
}
