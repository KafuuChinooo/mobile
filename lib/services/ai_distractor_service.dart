import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flash_card/model/deck.dart';

/// Quick Gemini client for generating distractors. Hardcoded key is for demo only.
class AiDistractorService {
  AiDistractorService({http.Client? client}) : _client = client ?? http.Client();

  static const String _apiKey = 'AIzaSyAFUztKCdx1fVCHW8DanryPeaArP09jwyw';
  static const String _model = 'gemini-1.5-flash-latest';

  final http.Client _client;

  Future<List<String>> generate({
    required String term,
    required String answer,
  }) async {
    _assertKey();

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    final prompt = '''
Generate exactly 3 Vietnamese distractors for a multiple-choice flashcard.
Term: "$term"
Correct answer: "$answer"
Rules: read and consider the context of the full deck, produce concise and plausible distractors, unique, and not equal or substring of the correct answer.
Return JSON only: {"distractors":["d1","d2","d3"]}''';

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('AI error ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final rawText = decoded['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    if (rawText == null || rawText.isEmpty) {
      throw Exception('Empty AI response: $decoded');
    }

    return _parseDistractors(rawText, answer);
  }

  /// Batch mode: generate distractors for many cards in one call.
  /// Returns a map cardId -> distractors.
  Future<Map<String, List<String>>> generateBatch(List<DeckCard> cards) async {
    _assertKey();
    if (cards.isEmpty) return {};

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    final buffer = StringBuffer();
    buffer.writeln('You are a generator of Vietnamese distractors. Read and consider all items (full deck context) before generating.');
    buffer.writeln('For each item, return exactly 3 distractors.');
    buffer.writeln('Items:');
    for (final card in cards) {
      buffer.writeln('- id:"${card.id}", term:"${card.term}", answer:"${card.definition}"');
    }
    buffer.writeln('Return JSON only, array of objects:');
    buffer.writeln('[{"id":"<id>","distractors":["d1","d2","d3"]}, ...]');
    buffer.writeln('Rules: concise, plausible, unique per item, not equal or substring of the correct answer.');

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': buffer.toString()}
            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('AI error ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final rawText = decoded['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    if (rawText == null || rawText.isEmpty) {
      throw Exception('Empty AI response: $decoded');
    }

    List<dynamic> parsedArray;
    try {
      parsedArray = jsonDecode(rawText) as List<dynamic>;
    } catch (_) {
      throw FormatException('AI batch response is not valid JSON: $rawText');
    }

    final result = <String, List<String>>{};
    for (final item in parsedArray) {
      if (item is! Map) continue;
      final id = item['id']?.toString() ?? '';
      final distractorList = item['distractors'] as List?;
      if (id.isEmpty || distractorList == null) continue;
      final answer = cards.firstWhere((c) => c.id == id, orElse: () => DeckCard(term: '', definition: '', id: 'missing')).definition;
      final cleaned = _cleanDistractors(distractorList, answer);
      if (cleaned.length >= 3) {
        result[id] = cleaned.take(3).toList();
      }
    }

    return result;
  }

  void dispose() {
    _client.close();
  }

  void _assertKey() {
    if (_apiKey.isEmpty || _apiKey == 'PUT_YOUR_API_KEY_HERE') {
      throw StateError('Set your Gemini API key in AiDistractorService._apiKey before calling generate.');
    }
  }

  List<String> _parseDistractors(String rawText, String answer) {
    late final Map<String, dynamic> parsedJson;
    try {
      parsedJson = jsonDecode(rawText) as Map<String, dynamic>;
    } catch (_) {
      throw FormatException('AI response is not valid JSON: $rawText');
    }

    final rawList = (parsedJson['distractors'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final cleaned = _cleanDistractors(rawList, answer);

    if (cleaned.length < 3) {
      throw Exception('Not enough valid distractors: $cleaned');
    }

    return cleaned.take(3).toList();
  }

  List<String> _cleanDistractors(List<dynamic> rawList, String answer) {
    final cleaned = <String>[];
    for (final item in rawList) {
      final trimmed = item.toString().trim();
      if (trimmed.isEmpty) continue;
      if (_equalsOrContains(trimmed, answer)) continue;
      if (cleaned.contains(trimmed)) continue;
      cleaned.add(trimmed);
    }
    return cleaned;
  }

  bool _equalsOrContains(String a, String b) {
    final la = a.toLowerCase();
    final lb = b.toLowerCase();
    return la == lb || la.contains(lb) || lb.contains(la);
  }
}
