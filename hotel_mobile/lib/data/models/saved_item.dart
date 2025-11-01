class SavedItem {
  final String id;
  final String itemId; // ID of the saved item (e.g., hotel_id, activity_id)
  final String type; // 'hotel', 'activity', 'destination'
  final String name;
  final String? location;
  final String? price;
  final String? imageUrl;
  final DateTime savedAt;
  final Map<String, dynamic>? metadata;

  SavedItem({
    required this.id,
    required this.itemId,
    required this.type,
    required this.name,
    this.location,
    this.price,
    this.imageUrl,
    required this.savedAt,
    this.metadata,
  });

  factory SavedItem.fromJson(Map<String, dynamic> json) {
    return SavedItem(
      id: json['id']?.toString() ?? '',
      itemId: json['itemId']?.toString() ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      location: json['location'],
      price: json['price'],
      imageUrl: json['imageUrl'],
      savedAt: DateTime.parse(json['savedAt']),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'type': type,
      'name': name,
      'location': location,
      'price': price,
      'imageUrl': imageUrl,
      'savedAt': savedAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}
