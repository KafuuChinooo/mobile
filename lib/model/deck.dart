import 'package:cloud_firestore/cloud_firestore.dart';

class DeckCard {
  final String front;
  final String back;
  final String? imageUrl;

  const DeckCard({
    required this.front,
    required this.back,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        'front': front,
        'back': back,
        'imageUrl': imageUrl,
      };

  factory DeckCard.fromJson(Map<String, dynamic> json) {
    return DeckCard(
      front: (json['front'] ?? '') as String,
      back: (json['back'] ?? '') as String,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

class Deck {
  final String id;
  final String title;
  final String description;
  final String authorId;
  final int cardCount;
  final DateTime createdAt;
  final bool isPublic;
  final List<String> tags;
  final String category;
  List<DeckCard> cards;

  Deck({
    required this.id,
    required this.title,
    required this.description,
    required this.authorId,
    required this.cardCount,
    required this.createdAt,
    this.isPublic = true, // Giá trị mặc định
    this.tags = const [], // Giá trị mặc định
    this.category = '', // Giá trị mặc định
    this.cards = const [],
  });

  Deck copyWith({
    String? id,
    String? title,
    String? description,
    String? authorId,
    int? cardCount,
    DateTime? createdAt,
    bool? isPublic,
    List<String>? tags,
    String? category,
    List<DeckCard>? cards,
  }) {
    return Deck(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      authorId: authorId ?? this.authorId,
      cardCount: cardCount ?? this.cardCount,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      cards: cards ?? this.cards,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'authorId': authorId,
        'cardCount': cardCount,
        'created_at': FieldValue.serverTimestamp(), // Đổi tên field
        'isPublic': isPublic,
        'tags': tags,
        'category': category,
      };

  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      authorId: (json['authorId'] ?? '') as String,
      cardCount: (json['cardCount'] ?? 0) as int,
      createdAt: (json['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(), // Đổi tên field
      isPublic: (json['isPublic'] ?? true) as bool,
      tags: List<String>.from(json['tags'] ?? []),
      category: (json['category'] ?? '') as String,
    );
  }
}
