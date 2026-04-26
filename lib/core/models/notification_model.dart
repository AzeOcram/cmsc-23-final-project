// FILE LOCATION: lib/core/models/notification_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { newItem, newMessage }

class AppNotification {
  final String id;
  final String recipientId;
  final NotificationType type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;

  /// Optional deep-link data
  final String? itemId;
  final String? conversationId;
  final String? senderPhotoUrl;

  AppNotification({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    this.read = false,
    required this.createdAt,
    this.itemId,
    this.conversationId,
    this.senderPhotoUrl,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      recipientId: map['recipientId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'newItem'),
        orElse: () => NotificationType.newItem,
      ),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      read: map['read'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      itemId: map['itemId'],
      conversationId: map['conversationId'],
      senderPhotoUrl: map['senderPhotoUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
        'recipientId': recipientId,
        'type': type.name,
        'title': title,
        'body': body,
        'read': read,
        'createdAt': Timestamp.fromDate(createdAt),
        'itemId': itemId,
        'conversationId': conversationId,
        'senderPhotoUrl': senderPhotoUrl,
      };

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        recipientId: recipientId,
        type: type,
        title: title,
        body: body,
        read: read ?? this.read,
        createdAt: createdAt,
        itemId: itemId,
        conversationId: conversationId,
        senderPhotoUrl: senderPhotoUrl,
      );
}
