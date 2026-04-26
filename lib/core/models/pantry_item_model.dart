// FILE LOCATION: lib/core/models/pantry_item_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum ItemStatus { available, reserved, completed, expired }

const List<String> kItemCategories = [
  'Fruits',
  'Vegetables',
  'Grains & Rice',
  'Bread & Pastries',
  'Dairy',
  'Eggs',
  'Meat',
  'Seafood',
  'Condiments',
  'Spices & Herbs',
  'Beverages',
  'Snacks',
  'Cooked Meals',
  'Desserts',
  'Other',
];

class PantryItem {
  final String id;
  final String giverId;
  final String giverName;
  final String? giverPhotoUrl;
  final bool giverVerified;

  final String title;
  final String description;
  final String category;
  final List<String> dietaryTags;
  final String photoUrl; // Cloudinary URL
  final String? publicId; // Cloudinary public_id for deletion

  final double quantity;
  final String unit; // e.g. "pieces", "kg", "cups"

  final DateTime expirationDate;
  final DateTime postedAt;

  final double? latitude;
  final double? longitude;
  final String? address;

  final ItemStatus status;
  final String? claimerId;
  final String? claimerName;
  final DateTime? meetupTime;
  final String? qrToken; // set when handshake is generated

  PantryItem({
    required this.id,
    required this.giverId,
    required this.giverName,
    this.giverPhotoUrl,
    this.giverVerified = false,
    required this.title,
    required this.description,
    required this.category,
    this.dietaryTags = const [],
    required this.photoUrl,
    this.publicId,
    required this.quantity,
    required this.unit,
    required this.expirationDate,
    required this.postedAt,
    this.latitude,
    this.longitude,
    this.address,
    this.status = ItemStatus.available,
    this.claimerId,
    this.claimerName,
    this.meetupTime,
    this.qrToken,
  });

  factory PantryItem.fromMap(Map<String, dynamic> map, String id) {
    return PantryItem(
      id: id,
      giverId: map['giverId'] ?? '',
      giverName: map['giverName'] ?? '',
      giverPhotoUrl: map['giverPhotoUrl'],
      giverVerified: map['giverVerified'] ?? false,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Other',
      dietaryTags: List<String>.from(map['dietaryTags'] ?? []),
      photoUrl: map['photoUrl'] ?? '',
      publicId: map['publicId'],
      quantity: (map['quantity'] ?? 1).toDouble(),
      unit: map['unit'] ?? 'pieces',
      expirationDate:
          (map['expirationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      postedAt: (map['postedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      address: map['address'],
      status: ItemStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'available'),
        orElse: () => ItemStatus.available,
      ),
      claimerId: map['claimerId'],
      claimerName: map['claimerName'],
      meetupTime: (map['meetupTime'] as Timestamp?)?.toDate(),
      qrToken: map['qrToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'giverId': giverId,
      'giverName': giverName,
      'giverPhotoUrl': giverPhotoUrl,
      'giverVerified': giverVerified,
      'title': title,
      'description': description,
      'category': category,
      'dietaryTags': dietaryTags,
      'photoUrl': photoUrl,
      'publicId': publicId,
      'quantity': quantity,
      'unit': unit,
      'expirationDate': Timestamp.fromDate(expirationDate),
      'postedAt': Timestamp.fromDate(postedAt),
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'status': status.name,
      'claimerId': claimerId,
      'claimerName': claimerName,
      'meetupTime': meetupTime != null ? Timestamp.fromDate(meetupTime!) : null,
      'qrToken': qrToken,
    };
  }

  PantryItem copyWith({
    ItemStatus? status,
    String? claimerId,
    String? claimerName,
    DateTime? meetupTime,
    String? qrToken,
    double? quantity,
  }) {
    return PantryItem(
      id: id,
      giverId: giverId,
      giverName: giverName,
      giverPhotoUrl: giverPhotoUrl,
      giverVerified: giverVerified,
      title: title,
      description: description,
      category: category,
      dietaryTags: dietaryTags,
      photoUrl: photoUrl,
      publicId: publicId,
      quantity: quantity ?? this.quantity,
      unit: unit,
      expirationDate: expirationDate,
      postedAt: postedAt,
      latitude: latitude,
      longitude: longitude,
      address: address,
      status: status ?? this.status,
      claimerId: claimerId ?? this.claimerId,
      claimerName: claimerName ?? this.claimerName,
      meetupTime: meetupTime ?? this.meetupTime,
      qrToken: qrToken ?? this.qrToken,
    );
  }

  bool get isExpired => expirationDate.isBefore(DateTime.now());
  bool get isAvailable => status == ItemStatus.available && !isExpired;
}
