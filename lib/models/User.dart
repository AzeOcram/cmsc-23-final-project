class User {
  final String id;
  final String name;
  final String initials;
  final bool isVerified;
  final int itemsShared;
  final int itemsReceived;
  final double rating;
  final List<String> dietaryPreferences;

  User({
    required this.id,
    required this.name,
    required this.initials,
    this.isVerified = false,
    this.itemsShared = 0,
    this.itemsReceived = 0,
    this.rating = 0.0,
    this.dietaryPreferences = const [],
  });

  // Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'initials': initials,
      'isVerified': isVerified,
      'itemsShared': itemsShared,
      'itemsReceived': itemsReceived,
      'rating': rating,
      'dietaryPreferences': dietaryPreferences,
    };
  }

  // Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      initials: json['initials'] as String,
      isVerified: json['isVerified'] as bool? ?? false,
      itemsShared: json['itemsShared'] as int? ?? 0,
      itemsReceived: json['itemsReceived'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      dietaryPreferences: (json['dietaryPreferences'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  // Create a copy with updated fields
  User copyWith({
    String? id,
    String? name,
    String? initials,
    bool? isVerified,
    int? itemsShared,
    int? itemsReceived,
    double? rating,
    List<String>? dietaryPreferences,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      isVerified: isVerified ?? this.isVerified,
      itemsShared: itemsShared ?? this.itemsShared,
      itemsReceived: itemsReceived ?? this.itemsReceived,
      rating: rating ?? this.rating,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
    );
  }
}