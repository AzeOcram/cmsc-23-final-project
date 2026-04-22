class Product {
  final String id;
  final String name;
  final String? photoUrl;
  final String description;
  final bool isVerified;
  final List<String> tags;
  final String ownerId;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.description,
    this.isVerified = false,
    this.tags = const [],
    required this.ownerId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert Product to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'description': description,
      'isVerified': isVerified,
      'tags': tags,
      'ownerId': ownerId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create Product from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      description: json['description'] as String,
      isVerified: json['isVerified'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      ownerId: json['ownerId'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  // Create a copy with updated fields
  Product copyWith({
    String? id,
    String? name,
    String? photoUrl,
    String? description,
    bool? isVerified,
    List<String>? tags,
    String? ownerId,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      description: description ?? this.description,
      isVerified: isVerified ?? this.isVerified,
      tags: tags ?? this.tags,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}