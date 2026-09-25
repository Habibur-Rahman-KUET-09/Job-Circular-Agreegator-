import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/scraper_source.dart';

/// Job sites admins add from the app (Firestore `scraperSources`, admin only).
class ScraperSourceService {
  final FirebaseFirestore _firestore;

  ScraperSourceService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _sources => _firestore.collection('scraperSources');

  Stream<List<ScraperSource>> watchSources() {
    return _sources.snapshots().map((snapshot) {
      final sources = snapshot.docs.map((doc) => ScraperSource.fromMap(doc.id, doc.data())).toList();
      sources.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return sources;
    });
  }

  Future<void> save(ScraperSource source) async {
    final data = {...source.toMap(), 'updatedAt': DateTime.now().toIso8601String()};
    if (source.id == null) {
      await _sources.add({...data, 'createdAt': DateTime.now().toIso8601String()});
    } else {
      await _sources.doc(source.id).update(data);
    }
  }

  Future<void> setEnabled(String id, bool enabled) {
    return _sources.doc(id).update({'enabled': enabled, 'updatedAt': DateTime.now().toIso8601String()});
  }

  Future<void> delete(String id) => _sources.doc(id).delete();
}
