// FILE LOCATION: lib/core/services/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  // New item notification

  // Called after a new pantry item is posted.
  // Queries all users whose dietaryTags or interestTags overlap with theitem's category/dietary tags, then writes a notification to each
  static Future<void> notifyMatchingUsers({
    required String itemId,
    required String itemTitle,
    required String giverName,
    required String giverId,
    required String category,
    required List<String> dietaryTags,
  }) async {
    try {
      // Fetch all users except the giver
      final usersSnap = await _db.collection('users').get();

      final batch = _db.batch();
      int count = 0;

      for (final doc in usersSnap.docs) {
        final uid = doc.id;
        if (uid == giverId) continue;

        final data = doc.data();
        final List<String> interests =
            List<String>.from(data['interestTags'] ?? []);
        final List<String> dietary =
            List<String>.from(data['dietaryTags'] ?? []);

        // Check if this user is interested in this category or dietary tag
        final bool categoryMatch = interests.contains(category);
        final bool dietaryMatch =
            dietaryTags.any((tag) => dietary.contains(tag));

        if (!categoryMatch && !dietaryMatch) continue;

        // Build a readable reason
        String matchReason = '';
        if (categoryMatch) matchReason = category;
        if (dietaryMatch && matchReason.isEmpty)
          matchReason = dietaryTags.first;

        final notifId = _uuid.v4();
        final notif = AppNotification(
          id: notifId,
          recipientId: uid,
          type: NotificationType.newItem,
          title: 'New item you might want! 🌻',
          body:
              '$giverName just shared "$itemTitle" — matches your $matchReason preference.',
          createdAt: DateTime.now(),
          itemId: itemId,
        );

        batch.set(
          _db.collection('notifications').doc(notifId),
          notif.toMap(),
        );

        count++;
        // Firestore batch limit is 500
        if (count >= 490) break;
      }

      if (count > 0) await batch.commit();
    } catch (e) {
      // Non-fatal — notifications are best-effort
    }
  }

  // New message notification

  /// Called after a message is sent.
  /// Writes a single notification to the recipient.
  static Future<void> notifyNewMessage({
    required String recipientId,
    required String senderName,
    String? senderPhotoUrl,
    required String messagePreview,
    required String conversationId,
  }) async {
    try {
      final notifId = _uuid.v4();
      final notif = AppNotification(
        id: notifId,
        recipientId: recipientId,
        type: NotificationType.newMessage,
        title: '$senderName sent you a message 💬',
        body: messagePreview.length > 60
            ? '${messagePreview.substring(0, 60)}...'
            : messagePreview,
        createdAt: DateTime.now(),
        conversationId: conversationId,
        senderPhotoUrl: senderPhotoUrl,
      );

      await _db.collection('notifications').doc(notifId).set(notif.toMap());
    } catch (e) {
      // Non-fatal
    }
  }
}
