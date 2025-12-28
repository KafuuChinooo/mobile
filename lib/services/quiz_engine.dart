import 'dart:math';

import 'package:flash_card/model/deck.dart';
import 'package:flash_card/services/quiz_rules.dart';

/// Builds quiz questions from deck cards (pure logic, UI-agnostic).
class QuizEngine {
  const QuizEngine({Random? random}) : _random = random;

  final Random? _random;

  List<QuizQuestion> buildQuestions(List<DeckCard> cards) {
    if (cards.isEmpty) return [];

    final shuffledCards = List<DeckCard>.from(cards);
    shuffledCards.shuffle(_random);

    return shuffledCards.map((card) {
      // Front side (term) becomes the question prompt; back side (definition) becomes the answer.
      final prompt = card.term;
      final answer = card.definition.isNotEmpty ? card.definition : card.term;
      final wrongAnswers = _buildWrongAnswers(
        card: card,
        allCards: shuffledCards,
        correctAnswer: answer,
      );
      final options = [answer, ...wrongAnswers]..shuffle(_random);

      return QuizQuestion(
        cardId: card.id,
        term: prompt,
        correctAnswer: answer,
        options: options,
      );
    }).toList();
  }

  List<String> _buildWrongAnswers({
    required DeckCard card,
    required List<DeckCard> allCards,
    required String correctAnswer,
  }) {
    final normalizedCorrect = correctAnswer.trim().toLowerCase();
    final wrongAnswers = <String>[];
    final seen = <String>{};

    void addIfValid(String? value) {
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) return;
      final lower = trimmed.toLowerCase();
      if (lower == normalizedCorrect) return;
      if (!seen.add(lower)) return;
      wrongAnswers.add(trimmed);
    }

    // Prefer pre-generated distractors (should match back-side style).
    for (final distractor in card.distractors ?? <String>[]) {
      addIfValid(distractor);
      if (wrongAnswers.length == requiredDistractorsPerCard) return wrongAnswers;
    }

    // Otherwise, pull other cards' back side (definition) to keep format similar.
    final otherDefinitions = allCards
        .where((c) => c.id != card.id)
        .map((c) => c.definition.isNotEmpty ? c.definition : c.term)
        .toList()
      ..shuffle(_random);
    for (final candidate in otherDefinitions) {
      addIfValid(candidate);
      if (wrongAnswers.length == requiredDistractorsPerCard) return wrongAnswers;
    }

    var fillerIndex = 1;
    while (wrongAnswers.length < requiredDistractorsPerCard) {
      addIfValid('Other choice #$fillerIndex');
      fillerIndex++;
    }

    return wrongAnswers;
  }
}

class QuizQuestion {
  final String cardId;
  final String term;
  final String correctAnswer;
  final List<String> options;

  const QuizQuestion({
    required this.cardId,
    required this.term,
    required this.correctAnswer,
    required this.options,
  });
}
