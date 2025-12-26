import 'dart:math';

import 'package:flash_card/data/deck_repository.dart';
import 'package:flash_card/model/deck.dart';
import 'package:flash_card/services/distractor_provider.dart';
import 'package:flash_card/services/quiz_rules.dart';

class QuizPrepException implements Exception {
  QuizPrepException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Prepares deck data for the quiz flow: ensures cards are loaded and have distractors.
class QuizPrepService {
  QuizPrepService({
    required DeckRepository repository,
    required DistractorProvider distractorProvider,
    int? batchSize,
  })  : _repository = repository,
        _distractorProvider = distractorProvider,
        _batchSize = batchSize ?? 10;

  final DeckRepository _repository;
  final DistractorProvider _distractorProvider;
  final int _batchSize;

  /// Loads cards (if missing), generates distractors where needed, and returns
  /// an updated list of cards. Emits progress 0..1 when provided.
  Future<List<DeckCard>> prepare(
    Deck deck, {
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0);

    // Ensure cards are loaded.
    final existingCards = deck.cards;
    final cards = existingCards.isNotEmpty ? List<DeckCard>.from(existingCards) : await _repository.fetchCards(deck.id);

    if (cards.length < minCardsForQuiz) {
      throw QuizPrepException(minCardErrorMessage);
    }

    // Find cards needing distractors.
    final needing = cards.where((c) => (c.distractors?.length ?? 0) < requiredDistractorsPerCard).toList();
    if (needing.isEmpty) {
      onProgress?.call(1);
      return cards;
    }

    int processed = 0;
    for (var i = 0; i < needing.length; i += _batchSize) {
      final chunk = needing.sublist(i, min(i + _batchSize, needing.length));
      try {
        final generated = await _distractorProvider.generateBatch(chunk);
        for (final card in chunk) {
          final distractors = generated[card.id];
          if (distractors != null && distractors.length >= requiredDistractorsPerCard) {
            final updated = card.copyWith(distractors: distractors);
            final idx = cards.indexWhere((c) => c.id == card.id);
            if (idx != -1) {
              cards[idx] = updated;
            }
            await _repository.updateCardDistractors(deck.id, card.id, distractors);
          }
        }
      } finally {
        processed += chunk.length;
        onProgress?.call(processed / needing.length);
      }
    }

    onProgress?.call(1);
    return cards;
  }
}
