import 'package:cloud_firestore/cloud_firestore.dart';

import 'cycle_repository.dart';
import 'models.dart';

class FirestoreCycleRepository implements CycleRepository {
  FirestoreCycleRepository({required this.userId})
      : _firestore = FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _userDocument =>
      _firestore.collection('users').doc(userId);

  CollectionReference<Map<String, dynamic>> get _logsCollection =>
      _firestore.collection('users').doc(userId).collection('logs');

  CollectionReference<Map<String, dynamic>> get _cyclesCollection =>
      _firestore.collection('users').doc(userId).collection('cycles');

  @override
  Stream<List<CycleLog>> watchLogs() {
    return _logsCollection.orderBy('date').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => CycleLog.fromMap(
                  {...doc.data(), 'id': doc.id, 'userId': userId}))
              .toList(growable: false),
        );
  }

  @override
  Future<List<CycleLog>> fetchLogs() async {
    final query = await _logsCollection.orderBy('date').get();
    return query.docs
        .map((doc) =>
            CycleLog.fromMap({...doc.data(), 'id': doc.id, 'userId': userId}))
        .toList(growable: false);
  }

  @override
  Future<void> saveLog(CycleLog log) async {
    await _logsCollection.doc(log.id).set(
          log.copyWith(userId: userId).toMap(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> deleteLog(String id) async {
    await _logsCollection.doc(id).delete();
  }

  @override
  Stream<List<CyclePeriod>> watchCycles() {
    return _cyclesCollection.orderBy('startDate').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => CyclePeriod.fromMap(
                  {...doc.data(), 'id': doc.id, 'userId': userId}))
              .toList(growable: false),
        );
  }

  @override
  Future<List<CyclePeriod>> fetchCycles() async {
    final query = await _cyclesCollection.orderBy('startDate').get();
    return query.docs
        .map((doc) => CyclePeriod.fromMap(
            {...doc.data(), 'id': doc.id, 'userId': userId}))
        .toList(growable: false);
  }

  @override
  Future<void> saveCycle(CyclePeriod cycle) async {
    await _cyclesCollection.doc(cycle.id).set(
          cycle.copyWith(userId: userId).toMap(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> deleteCycle(String id) async {
    await _cyclesCollection.doc(id).delete();
  }

  @override
  Future<CycleSettings?> loadSettings() async {
    final doc = await _userDocument.get();
    final data = doc.data();
    if (data == null || data.isEmpty) {
      return null;
    }
    if (data.containsKey('averageCycleLength') ||
        data.containsKey('periodLength')) {
      return CycleSettings.fromMap(data);
    }
    return null;
  }

  @override
  Future<void> saveSettings(CycleSettings settings) async {
    await _userDocument.set(settings.toMap(), SetOptions(merge: true));
  }

  void dispose() {}
}
