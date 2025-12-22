import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class DeckCard {
  final String id;
  final String term;
  final String definition;
  final String? imageUrl;

  DeckCard({
    String? id,
    required this.term,
    required this.definition,
    this.imageUrl,
  }) : id = id ?? const Uuid().v4();

  // Backward compatibility getters
  String get front => term;
  String get back => definition;

  Map<String, dynamic> toJson() => {
        'id': id,
        'term': term,
        'definition': definition,
        'front': term, 
        'back': definition,
        'imageUrl': imageUrl,
      };

  factory DeckCard.fromJson(Map<String, dynamic> json) {
    return DeckCard(
      id: json['id'] as String?,
      term: (json['term'] ?? json['front'] ?? '') as String,
      definition: (json['definition'] ?? json['back'] ?? '') as String,
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
  final DateTime? lastOpenedAt;
  final bool isPublic;
  final List<String> tags;
  final String category;
  final double progress; // 0.0 to 1.0
  final int lastStudiedIndex; // Lưu vị trí thẻ đang học dở
  List<DeckCard> cards; // Remove final here to make it mutable

  Deck({
    required this.id,
    required this.title,
    required this.description,
    required this.authorId,
    required this.cardCount,
    required this.createdAt,
    this.lastOpenedAt,
    this.isPublic = true,
    this.tags = const [],
    this.category = '',
    this.progress = 0.0,
    this.lastStudiedIndex = 0,
    this.cards = const [],
  });

  Deck copyWith({
    String? id,
    String? title,
    String? description,
    String? authorId,
    int? cardCount,
    DateTime? createdAt,
    DateTime? lastOpenedAt,
    bool? isPublic,
    List<String>? tags,
    String? category,
    double? progress,
    int? lastStudiedIndex,
    List<DeckCard>? cards,
  }) {
    return Deck(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      authorId: authorId ?? this.authorId,
      cardCount: cardCount ?? this.cardCount,
      createdAt: createdAt ?? this.createdAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      progress: progress ?? this.progress,
      lastStudiedIndex: lastStudiedIndex ?? this.lastStudiedIndex,
      cards: cards ?? this.cards,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'authorId': authorId,
        'cardCount': cardCount,
        'created_at': FieldValue.serverTimestamp(),
        'last_opened_at': lastOpenedAt == null ? null : Timestamp.fromDate(lastOpenedAt!),
        'isPublic': isPublic,
        'tags': tags,
        'category': category,
        'progress': progress,
        'last_studied_index': lastStudiedIndex,
      };

  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      authorId: (json['authorId'] ?? '') as String,
      cardCount: (json['cardCount'] ?? 0) as int,
      createdAt: (json['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastOpenedAt: (json['last_opened_at'] as Timestamp?)?.toDate(),
      isPublic: (json['isPublic'] ?? true) as bool,
      tags: List<String>.from(json['tags'] ?? []),
      category: (json['category'] ?? '') as String,
      progress: (json['progress'] ?? 0.0).toDouble(),
      lastStudiedIndex: (json['last_studied_index'] ?? 0) as int,
    );
  }
}
