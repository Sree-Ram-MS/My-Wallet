class Category {
  final String id;
  final String name;
  final String color; // Hex string e.g., "0xFFFF9800"
  final String icon;  // Name of the icon identifier
  final String? parentId;
  final bool isArchived;

  Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    this.parentId,
    required this.isArchived,
  });

  Category copyWith({
    String? id,
    String? name,
    String? color,
    String? icon,
    String? parentId,
    bool? isArchived,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      parentId: parentId ?? this.parentId,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'parentId': parentId,
      'isArchived': isArchived ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      color: map['color'] ?? '0xFF9E9E9E',
      icon: map['icon'] ?? 'category',
      parentId: map['parentId'],
      isArchived: (map['isArchived'] ?? 0) == 1,
    );
  }
}
