// FILE LOCATION: lib/core/providers/notification_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _panelOpen = false;
  bool get panelOpen => _panelOpen;

  void togglePanel() {
    _panelOpen = !_panelOpen;
    notifyListeners();
  }

  void closePanel() {
    if (_panelOpen) {
      _panelOpen = false;
      notifyListeners();
    }
  }

  // Streams

  /// Stream of the 30 most recent notifications for the current user.
  Stream<List<AppNotification>> notificationsStream(String uid) {
    return _db
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotification.fromMap(d.data(), d.id))
            .toList());
  }

  /// Stream of the unread notification count for the bell badge.
  Stream<int> unreadCountStream(String uid) {
    return _db
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.size);
  }

  // Actions

  Future<void> markAllRead(String uid) async {
    try {
      final snap = await _db
          .collection('notifications')
          .where('recipientId', isEqualTo: uid)
          .where('read', isEqualTo: false)
          .get();

      if (snap.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> markOneRead(String notifId) async {
    try {
      await _db.collection('notifications').doc(notifId).update({'read': true});
    } catch (_) {}
  }

  Future<void> deleteNotification(String notifId) async {
    try {
      await _db.collection('notifications').doc(notifId).delete();
    } catch (_) {}
  }
}
