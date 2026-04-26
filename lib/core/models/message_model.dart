// FILE LOCATION: lib/core/models/message_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class AppMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String text;
  final DateTime sentAt;
  final bool read;

  AppMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.text,
    required this.sentAt,
    this.read = false,
  });

  factory AppMessage.fromMap(Map<String, dynamic> map, String id) {
    return AppMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderPhotoUrl: map['senderPhotoUrl'],
      text: map['text'] ?? '',
      sentAt: (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: map['read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderName': senderName,
        'senderPhotoUrl': senderPhotoUrl,
        'text': text,
        'sentAt': Timestamp.fromDate(sentAt),
        'read': read,
      };
}

class Conversation {
  final String id;

  final String giverId;
  final String giverName;
  final String? giverPhotoUrl;

  final String claimerId;
  final String claimerName;
  final String? claimerPhotoUrl;

  final String itemId;
  final String itemTitle;
  final String? itemPhotoUrl;

  final String? lastMessage;
  final DateTime? lastMessageAt;

  /// Per-user unread counts: { uid: count }
  /// Only the recipient's count is incremented when a message is sent.
  final Map<String, int> unreadCounts;

  Conversation({
    required this.id,
    required this.giverId,
    required this.giverName,
    this.giverPhotoUrl,
    required this.claimerId,
    required this.claimerName,
    this.claimerPhotoUrl,
    required this.itemId,
    required this.itemTitle,
    this.itemPhotoUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCounts = const {},
  });

  /// Returns the unread count for a specific user.
  int unreadCountFor(String uid) => unreadCounts[uid] ?? 0;

  factory Conversation.fromMap(Map<String, dynamic> map, String id) {
    // Handle both old unreadCount (int) and new unreadCounts (map)
    // for backwards compatibility with any existing Firestore documents.
    Map<String, int> counts = {};
    if (map['unreadCounts'] != null) {
      (map['unreadCounts'] as Map<String, dynamic>).forEach((k, v) {
        counts[k] = (v as num).toInt();
      });
    }

    return Conversation(
      id: id,
      giverId: map['giverId'] ?? '',
      giverName: map['giverName'] ?? '',
      giverPhotoUrl: map['giverPhotoUrl'],
      claimerId: map['claimerId'] ?? '',
      claimerName: map['claimerName'] ?? '',
      claimerPhotoUrl: map['claimerPhotoUrl'],
      itemId: map['itemId'] ?? '',
      itemTitle: map['itemTitle'] ?? '',
      itemPhotoUrl: map['itemPhotoUrl'],
      lastMessage: map['lastMessage'],
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
      unreadCounts: counts,
    );
  }

  Map<String, dynamic> toMap() => {
        'giverId': giverId,
        'giverName': giverName,
        'giverPhotoUrl': giverPhotoUrl,
        'claimerId': claimerId,
        'claimerName': claimerName,
        'claimerPhotoUrl': claimerPhotoUrl,
        'itemId': itemId,
        'itemTitle': itemTitle,
        'itemPhotoUrl': itemPhotoUrl,
        'lastMessage': lastMessage,
        'lastMessageAt':
            lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
        'unreadCounts': unreadCounts,
        'participants': [giverId, claimerId],
      };

  String otherName(String currentUid) =>
      currentUid == giverId ? claimerName : giverName;

  String? otherPhotoUrl(String currentUid) =>
      currentUid == giverId ? claimerPhotoUrl : giverPhotoUrl;

  String otherId(String currentUid) =>
      currentUid == giverId ? claimerId : giverId;
}
