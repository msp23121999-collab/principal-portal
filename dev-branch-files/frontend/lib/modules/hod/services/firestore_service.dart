import 'package:cloud_firestore/cloud_firestore.dart';

/// Central Firestore service — all modules read/write through here.
/// Data persists across page refreshes in Firebase Firestore.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Collection References ────────────────────────────────────────────────
  CollectionReference get leaveRequests => _db.collection('leave_requests');
  CollectionReference get profileApprovals => _db.collection('profile_approvals');
  CollectionReference get notifications => _db.collection('notifications');
  CollectionReference get events => _db.collection('events');
  CollectionReference get files => _db.collection('files');
  CollectionReference get classAdvisers => _db.collection('class_advisers');
  CollectionReference get mentors => _db.collection('mentors');
  CollectionReference get hodProfile => _db.collection('hod_profile');
  CollectionReference get courseDiary => _db.collection('course_diary');

  // ─── Generic Helpers ──────────────────────────────────────────────────────

  /// Add a document, returns the new doc ID
  Future<String> addDoc(CollectionReference col, Map<String, dynamic> data) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await col.add(data);
    return ref.id;
  }

  /// Update specific fields on a document
  Future<void> updateDoc(CollectionReference col, String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await col.doc(id).update(data);
  }

  /// Delete a document
  Future<void> deleteDoc(CollectionReference col, String id) async {
    await col.doc(id).delete();
  }

  /// Set (overwrite) a document with known ID
  Future<void> setDoc(CollectionReference col, String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await col.doc(id).set(data, SetOptions(merge: true));
  }

  /// Get all docs once
  Future<QuerySnapshot> getAll(CollectionReference col) async {
    return col.orderBy('createdAt', descending: false).get();
  }

  /// Stream all docs (real-time)
  Stream<QuerySnapshot> streamAll(CollectionReference col, {String orderBy = 'createdAt'}) {
    return col.orderBy(orderBy, descending: false).snapshots();
  }

  // ─── Seed Default Data ────────────────────────────────────────────────────

  /// Called on app start — seeds default records if collections are empty.
  Future<void> seedDefaultDataIfEmpty() async {
    final doc = await hodProfile.doc('main').get();
    bool isCse = false;
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        final dept = (data['departmentId'] ?? data['department'] ?? '').toString().toUpperCase();
        isCse = dept.contains('CSE');
      }
    }
    
    if (isCse) {
      // Do not seed mock data for CSE, fetch only from database
      return;
    }

    await Future.wait([
      _seedIfEmpty(leaveRequests, _defaultLeaveRequests()),
      _seedIfEmpty(profileApprovals, _defaultProfileApprovals()),
      _seedIfEmpty(notifications, _defaultNotifications()),
      _seedIfEmpty(events, _defaultEvents()),
      _seedIfEmpty(files, _defaultFiles()),
      _seedIfEmpty(classAdvisers, _defaultClassAdvisers()),
      _seedMentorsIfEmptyOrLegacy(),
      _seedHodProfileIfEmpty(),
    ]);
  }

  Future<void> _seedIfEmpty(CollectionReference col, List<Map<String, dynamic>> defaults) async {
    final snapshot = await col.limit(1).get();
    if (snapshot.docs.isEmpty) {
      for (final data in defaults) {
        await addDoc(col, data);
      }
    }
  }

  Future<void> _seedMentorsIfEmptyOrLegacy() async {
    final snapshot = await mentors.get();
    bool isLegacy = false;
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first.data() as Map<String, dynamic>;
      if (!doc.containsKey('department_id') || !doc.containsKey('student_list')) {
        isLegacy = true;
      }
    }
    
    if (snapshot.docs.isEmpty || isLegacy) {
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      for (final data in _defaultMentors()) {
        await addDoc(mentors, data);
      }
    }
  }

  Future<void> _seedHodProfileIfEmpty() async {
    final doc = await hodProfile.doc('main').get();
    if (!doc.exists) {
      await setDoc(hodProfile, 'main', _defaultHodProfile());
    }
  }

  // ─── Default Seed Data ────────────────────────────────────────────────────

  Map<String, dynamic> _defaultHodProfile() => {};

  List<Map<String, dynamic>> _defaultLeaveRequests() => [];

  List<Map<String, dynamic>> _defaultProfileApprovals() => [];

  List<Map<String, dynamic>> _defaultNotifications() => [];

  List<Map<String, dynamic>> _defaultEvents() => [];

  List<Map<String, dynamic>> _defaultFiles() => [];

  List<Map<String, dynamic>> _defaultClassAdvisers() => [];

  List<Map<String, dynamic>> _defaultMentors() => [];
}
