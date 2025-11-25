import 'dart:async';
import 'package:flash_card/model/deck.dart';

abstract class DeckRepository {
  Future<List<Deck>> fetchDecks();
  Future<void> addDeck(Deck deck);

  static final DeckRepository instance = InMemoryDeckRepository._internal();
}

class InMemoryDeckRepository implements DeckRepository {
  final List<Deck> _decks = [];
  int _idCounter = 0;

  InMemoryDeckRepository._internal() {
    _seedData();
  }

  void _seedData() {
    if (_decks.isNotEmpty) return;
    _decks.add(
      Deck(
        id: _nextId(),
        title: 'Deck 2',
        description: 'Sample deck synced from local store',
        createdAt: DateTime.now(),
        cards: const [
          DeckCard(word: 'Hello', answer: 'Xin chào'),
          DeckCard(word: 'Food', answer: 'Thức ăn'),
        ],
      ),
    );
  }

  @override
  Future<List<Deck>> fetchDecks() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return List<Deck>.unmodifiable(_decks);
  }

  @override
  Future<void> addDeck(Deck deck) async {
    final newDeck = deck.id.isEmpty
        ? deck.copyWith(id: _nextId(), createdAt: DateTime.now())
        : deck;
    _decks.insert(0, newDeck);
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  String _nextId() {
    _idCounter += 1;
    return '${DateTime.now().microsecondsSinceEpoch}-$_idCounter';
  }
}
