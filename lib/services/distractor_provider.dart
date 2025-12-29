import 'package:flash_card/model/deck.dart';

/// Abstraction for generating distractors so we can swap/mock the provider.
abstract class DistractorProvider {
  /// Returns a map of cardId -> list of distractors (at least 3 items per card).
  // Sinh danh sách đáp án nhiễu cho nhiều thẻ
  Future<Map<String, List<String>>> generateBatch(
    List<DeckCard> cards, {
    List<DeckCard>? deckContext,
    String? deckTitle,
    String? deckDescription,
    List<String>? deckTags,
    String? deckCategory,
  });
}
