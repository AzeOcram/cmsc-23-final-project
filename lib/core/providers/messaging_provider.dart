// FILE LOCATION: lib/core/providers/messaging_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../services/notification_service.dart';

class MessagingProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String _convId(String itemId, String giverId, String claimerId) {
    final iSuffix =
        itemId.length >= 8 ? itemId.substring(itemId.length - 8) : itemId;
    final gSuffix =
        giverId.length >= 8 ? giverId.substring(giverId.length - 8) : giverId;
    final cSuffix = claimerId.length >= 8
        ? claimerId.substring(claimerId.length - 8)
        : claimerId;
    return 'conv_${iSuffix}_${gSuffix}_$cSuffix';
  }

  //  Conversations

  Stream<List<Conversation>> conversationsStream(String uid) {
    return _db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Conversation.fromMap(d.data(), d.id))
            .toList());
  }

  Future<Conversation?> getOrCreateConversation({
    required String giverId,
    required String giverName,
    String? giverPhotoUrl,
    required String claimerId,
    required String claimerName,
    String? claimerPhotoUrl,
    required String itemId,
    required String itemTitle,
    String? itemPhotoUrl,
  }) async {
    final id = _convId(itemId, giverId, claimerId);
    final ref = _db.collection('conversations').doc(id);

    final conv = Conversation(
      id: id,
      giverId: giverId,
      giverName: giverName,
      giverPhotoUrl: giverPhotoUrl,
      claimerId: claimerId,
      claimerName: claimerName,
      claimerPhotoUrl: claimerPhotoUrl,
      itemId: itemId,
      itemTitle: itemTitle,
      itemPhotoUrl: itemPhotoUrl,
      lastMessageAt: DateTime.now(),
      unreadCounts: const {},
    );

    try {
      await ref.set(conv.toMap(), SetOptions(merge: true));
      final snapshot = await ref.get();
      if (snapshot.exists) {
        return Conversation.fromMap(snapshot.data()!, snapshot.id);
      }
      return conv;
    } catch (e) {
      debugPrint('getOrCreateConversation error: $e');
      return null;
    }
  }

  //  Messages

  Stream<List<AppMessage>> messagesStream(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AppMessage.fromMap(d.data(), d.id)).toList());
  }

  /// Sends a message, increments only the recipient's unread count,
  /// and writes a notification doc for the recipient.
  Future<bool> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String recipientId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return false;
    try {
      final msgRef = _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc();

      final msg = AppMessage(
        id: msgRef.id,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        text: text.trim(),
        sentAt: DateTime.now(),
      );

      final batch = _db.batch();

      batch.set(msgRef, msg.toMap());

      batch.update(
        _db.collection('conversations').doc(conversationId),
        {
          'lastMessage': text.trim(),
          'lastMessageAt': Timestamp.fromDate(msg.sentAt),
          'unreadCounts.$recipientId': FieldValue.increment(1),
        },
      );

      await batch.commit();

      // Notify the recipient — fire-and-forget, non-fatal
      NotificationService.notifyNewMessage(
        recipientId: recipientId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        messagePreview: text.trim(),
        conversationId: conversationId,
      );

      return true;
    } catch (e) {
      debugPrint('sendMessage error: $e');
      return false;
    }
  }

  Future<void> markConversationRead(
      String conversationId, String currentUid) async {
    try {
      await _db
          .collection('conversations')
          .doc(conversationId)
          .update({'unreadCounts.$currentUid': 0});
    } catch (_) {}
  }

  Stream<int> totalUnreadStream(String uid) {
    return _db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs.fold<int>(
              0,
              (sum, doc) {
                final counts = doc.data()['unreadCounts'];
                if (counts == null || counts is! Map) return sum;
                final userCount = counts[uid];
                if (userCount == null) return sum;
                return sum + (userCount as num).toInt();
              },
            ));
  }
}
