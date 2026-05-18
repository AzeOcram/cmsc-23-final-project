// FILE LOCATION: lib/core/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

const List<String> kDietaryTags = [
  'Vegan',
  'Vegetarian',
  'Halal',
  'Kosher',
  'Gluten-Free',
  'Dairy-Free',
  'Nut-Free',
  'Raw Ingredients',
  'Home-Cooked',
  'Organic',
  'Seafood',
  'Meat',
];

const List<String> kInterestTags = [
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
];

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? verificationSelfieUrl;
  final bool isVerified;
  final List<String> dietaryTags;
  final List<String> interestTags;
  final double? latitude;
  final double? longitude;
  final String? address;
  final double discoveryRadiusKm;
  final bool notifNewItems;
  final bool notifPickupReminders;
  final bool notifMessages;
  final int totalGiven;
  final int totalReceived;
  final List<String> badges;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.verificationSelfieUrl,
    this.isVerified = false,
    this.dietaryTags = const [],
    this.interestTags = const [],
    this.latitude,
    this.longitude,
    this.address,
    this.discoveryRadiusKm = 5.0,
    this.notifNewItems = true,
    this.notifPickupReminders = true,
    this.notifMessages = true,
    this.totalGiven = 0,
    this.totalReceived = 0,
    this.badges = const [],
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      verificationSelfieUrl: map['verificationSelfieUrl'],
      isVerified: map['isVerified'] ?? false,
      dietaryTags: List<String>.from(map['dietaryTags'] ?? []),
      interestTags: List<String>.from(map['interestTags'] ?? []),
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      address: map['address'],
      discoveryRadiusKm: (map['discoveryRadiusKm'] ?? 5.0).toDouble(),
      notifNewItems: map['notifNewItems'] ?? true,
      notifPickupReminders: map['notifPickupReminders'] ?? true,
      notifMessages: map['notifMessages'] ?? true,
      totalGiven: map['totalGiven'] ?? 0,
      totalReceived: map['totalReceived'] ?? 0,
      badges: List<String>.from(map['badges'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'verificationSelfieUrl': verificationSelfieUrl,
      'isVerified': isVerified,
      'dietaryTags': dietaryTags,
      'interestTags': interestTags,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'discoveryRadiusKm': discoveryRadiusKm,
      'notifNewItems': notifNewItems,
      'notifPickupReminders': notifPickupReminders,
      'notifMessages': notifMessages,
      'totalGiven': totalGiven,
      'totalReceived': totalReceived,
      'badges': badges,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? verificationSelfieUrl,
    bool? isVerified,
    List<String>? dietaryTags,
    List<String>? interestTags,
    double? latitude,
    double? longitude,
    String? address,
    double? discoveryRadiusKm,
    bool? notifNewItems,
    bool? notifPickupReminders,
    bool? notifMessages,
    int? totalGiven,
    int? totalReceived,
    List<String>? badges,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      verificationSelfieUrl:
          verificationSelfieUrl ?? this.verificationSelfieUrl,
      isVerified: isVerified ?? this.isVerified,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      interestTags: interestTags ?? this.interestTags,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      discoveryRadiusKm: discoveryRadiusKm ?? this.discoveryRadiusKm,
      notifNewItems: notifNewItems ?? this.notifNewItems,
      notifPickupReminders: notifPickupReminders ?? this.notifPickupReminders,
      notifMessages: notifMessages ?? this.notifMessages,
      totalGiven: totalGiven ?? this.totalGiven,
      totalReceived: totalReceived ?? this.totalReceived,
      badges: badges ?? this.badges,
      createdAt: createdAt,
    );
  }
}
