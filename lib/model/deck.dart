class DeckCard {
  final String word;
  final String answer;

  const DeckCard({
    required this.word,
    required this.answer,
  });

  Map<String, dynamic> toJson() => {
        'word': word,
        'answer': answer,
      };

  factory DeckCard.fromJson(Map<String, dynamic> json) {
    return DeckCard(
      word: (json['word'] ?? '') as String,
      answer: (json['answer'] ?? '') as String,
    );
  }
}

class Deck {
  final String id;
  final String title;
  final String description;
  final List<DeckCard> cards;
  final DateTime createdAt;

  const Deck({
    required this.id,
    required this.title,
    required this.description,
    required this.cards,
    required this.createdAt,
  });

  Deck copyWith({
    String? id,
    String? title,
    String? description,
    List<DeckCard>? cards,
    DateTime? createdAt,
  }) {
    return Deck(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      cards: cards ?? this.cards,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'cards': cards.map((c) => c.toJson()).toList(),
      };

  factory Deck.fromJson(Map<String, dynamic> json) {
    final cardsJson = (json['cards'] as List<dynamic>? ?? [])
        .map((c) => DeckCard.fromJson(c as Map<String, dynamic>))
        .toList();
    return Deck(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      cards: cardsJson,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
