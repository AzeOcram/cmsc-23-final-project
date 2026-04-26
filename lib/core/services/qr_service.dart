// FILE LOCATION: lib/core/services/qr_service.dart

import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint
import '../models/pantry_item_model.dart';

class QrService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Generates a unique QR token for a pantry item and saves it to Firestore.
  static Future<String?> generateQrToken({
    required String itemId,
    required String giverId,
  }) async {
    try {
      final token = const Uuid().v4();

      final payload = {
        'itemId': itemId,
        'giverId': giverId,
        'token': token,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _db.collection('pantry_items').doc(itemId).update({
        'qrToken': token,
      });

      return jsonEncode(payload);
    } catch (e) {
      debugPrint("Error generating QR token: $e");
      return null;
    }
  }

  /// Validates a scanned QR code payload string.
  static Future<PantryItem?> validateQrPayload({
    required String rawPayload,
    required String scannerId,
  }) async {
    try {
      final Map<String, dynamic> payload = jsonDecode(rawPayload);

      final itemId = payload['itemId'] as String?;
      final token = payload['token'] as String?;

      if (itemId == null || token == null) return null;

      final ref = _db.collection('pantry_items').doc(itemId);
      final doc = await ref.get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      final storedToken = data['qrToken'] as String?;
      final claimerId = data['claimerId'] as String?;
      final status = data['status'] as String?;

      // Validate token, status, and that the scanner IS the claimer
      if (storedToken != token) return null;
      if (status != 'reserved') return null;
      if (claimerId != scannerId) return null;

      return PantryItem.fromMap(data, itemId);
    } catch (e) {
      debugPrint("Validation error: $e");
      return null;
    }
  }

  /// Marks the exchange as completed.
  static Future<bool> completeExchange({
    required String itemId,
  }) async {
    try {
      final ref = _db.collection('pantry_items').doc(itemId);
      final doc = await ref.get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final giverId = data['giverId'] as String?;
      final claimerId = data['claimerId'] as String?;

      // 1. PRIMARY ACTION: Mark item as completed.
      // This is the core transaction that MUST succeed.
      await ref.update({
        'status': 'completed',
        'qrToken': null,
      });

      // 2. SECONDARY ACTION: Update profile counters.
      // We wrap this in a separate try-catch because Firestore Security Rules
      // prevent users from writing to OTHER users' profiles.
      try {
        if (giverId != null && giverId.isNotEmpty) {
          // This will likely fail for the receiver (Permission Denied)
          await _db.collection('users').doc(giverId).update({
            'totalGiven': FieldValue.increment(1),
          });
        }
        if (claimerId != null && claimerId.isNotEmpty) {
          // This should succeed if the current user is the claimer
          await _db.collection('users').doc(claimerId).update({
            'totalReceived': FieldValue.increment(1),
          });
        }
      } catch (e) {
        // Log the error but DO NOT return false.
        // The exchange is technically done once the item status changes.
        debugPrint("Counter update skipped (Security Rules): $e");
      }

      return true;
    } catch (e) {
      debugPrint("Complete exchange error: $e");
      return false;
    }
  }
}
