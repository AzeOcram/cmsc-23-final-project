// FILE LOCATION: lib/core/providers/pantry_provider.dart
// CHANGE: addItem() now calls NotificationService.notifyMatchingUsers()
//         after successfully posting to Firestore.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/pantry_item_model.dart';
import '../services/cloudinary_service.dart';
import '../services/notification_service.dart';

class PantryProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  List<PantryItem> _feedItems = [];
  bool _loading = false;
  String? _error;

  String _searchQuery = '';
  List<String> _selectedCategories = [];
  List<String> _selectedDietary = [];
  String _sortBy = 'newest';

  List<PantryItem> get feedItems => _applyFilters(_feedItems);
  bool get loading => _loading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  List<String> get selectedCategories => _selectedCategories;
  List<String> get selectedDietary => _selectedDietary;
  String get sortBy => _sortBy;

  // Feed

  Stream<List<PantryItem>> feedStream({List<String>? interestTags}) {
    return _db
        .collection('pantry_items')
        .where('status', isEqualTo: 'available')
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snap) {
      final items = snap.docs
          .map(
              (d) => PantryItem.fromMap(d.data() as Map<String, dynamic>, d.id))
          .where((item) => !item.isExpired)
          .toList();
      _feedItems = items;
      return _applyFilters(items);
    });
  }

  List<PantryItem> _applyFilters(List<PantryItem> items) {
    var result = List<PantryItem>.from(items);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((i) =>
              i.title.toLowerCase().contains(q) ||
              i.description.toLowerCase().contains(q) ||
              i.category.toLowerCase().contains(q))
          .toList();
    }

    if (_selectedCategories.isNotEmpty) {
      result = result
          .where((i) => _selectedCategories.contains(i.category))
          .toList();
    }

    if (_selectedDietary.isNotEmpty) {
      result = result
          .where((i) => i.dietaryTags.any((t) => _selectedDietary.contains(t)))
          .toList();
    }

    switch (_sortBy) {
      case 'expiring':
        result.sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
        break;
      default:
        result.sort((a, b) => b.postedAt.compareTo(a.postedAt));
    }

    return result;
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleCategory(String cat) {
    if (_selectedCategories.contains(cat)) {
      _selectedCategories.remove(cat);
    } else {
      _selectedCategories.add(cat);
    }
    notifyListeners();
  }

  void toggleDietary(String tag) {
    if (_selectedDietary.contains(tag)) {
      _selectedDietary.remove(tag);
    } else {
      _selectedDietary.add(tag);
    }
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategories = [];
    _selectedDietary = [];
    _sortBy = 'newest';
    notifyListeners();
  }

  // My items / requests

  Stream<List<PantryItem>> myItemsStream(String uid) {
    return _db
        .collection('pantry_items')
        .where('giverId', isEqualTo: uid)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => PantryItem.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<PantryItem>> myRequestsStream(String uid) {
    return _db
        .collection('pantry_items')
        .where('claimerId', isEqualTo: uid)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => PantryItem.fromMap(d.data(), d.id)).toList());
  }

  // CREATE

  Future<String?> addItem({
    required String giverId,
    required String giverName,
    String? giverPhotoUrl,
    required bool giverVerified,
    required String title,
    required String description,
    required String category,
    required List<String> dietaryTags,
    required File imageFile,
    required double quantity,
    required String unit,
    required DateTime expirationDate,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Upload image to Cloudinary
      final upload = await CloudinaryService.uploadImage(
        imageFile,
        folder: 'pantryshare/items',
      );

      if (upload == null) {
        _error = 'Image upload failed. Please try again.';
        _loading = false;
        notifyListeners();
        return null;
      }

      // 2. Save to Firestore
      final id = _uuid.v4();
      final item = PantryItem(
        id: id,
        giverId: giverId,
        giverName: giverName,
        giverPhotoUrl: giverPhotoUrl,
        giverVerified: giverVerified,
        title: title,
        description: description,
        category: category,
        dietaryTags: dietaryTags,
        photoUrl: upload['url']!,
        publicId: upload['publicId'],
        quantity: quantity,
        unit: unit,
        expirationDate: expirationDate,
        postedAt: DateTime.now(),
        latitude: latitude,
        longitude: longitude,
        address: address,
      );

      await _db.collection('pantry_items').doc(id).set(item.toMap());

      // 3. Notify matching users (fire-and-forget — non-fatal)
      NotificationService.notifyMatchingUsers(
        itemId: id,
        itemTitle: title,
        giverName: giverName,
        giverId: giverId,
        category: category,
        dietaryTags: dietaryTags,
      );

      _loading = false;
      notifyListeners();
      return id;
    } catch (e) {
      _error = 'Failed to post item: $e';
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  // UPDATE / DELETE

  Future<bool> updateItem(String id, Map<String, dynamic> updates) async {
    try {
      await _db.collection('pantry_items').doc(id).update(updates);
      return true;
    } catch (e) {
      _error = 'Failed to update item.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(String id) async {
    try {
      await _db.collection('pantry_items').doc(id).delete();
      return true;
    } catch (e) {
      _error = 'Failed to delete item.';
      notifyListeners();
      return false;
    }
  }

  // CLAIMING

  Future<bool> requestItem({
    required String itemId,
    required String claimerId,
    required String claimerName,
    required DateTime meetupTime,
  }) async {
    try {
      await _db.collection('pantry_items').doc(itemId).update({
        'status': 'reserved',
        'claimerId': claimerId,
        'claimerName': claimerName,
        'meetupTime': Timestamp.fromDate(meetupTime),
      });
      return true;
    } catch (e) {
      _error = 'Failed to request item.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelRequest(String itemId) async {
    try {
      await _db.collection('pantry_items').doc(itemId).update({
        'status': 'available',
        'claimerId': null,
        'claimerName': null,
        'meetupTime': null,
        'qrToken': null,
      });
      return true;
    } catch (e) {
      _error = 'Failed to cancel request.';
      notifyListeners();
      return false;
    }
  }

  Future<PantryItem?> getItemById(String id) async {
    try {
      final doc = await _db.collection('pantry_items').doc(id).get();
      if (doc.exists) {
        return PantryItem.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
