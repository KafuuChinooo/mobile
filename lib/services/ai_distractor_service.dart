import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flash_card/model/deck.dart';
import 'package:flash_card/services/distractor_provider.dart';

/// Quick Gemini client for generating distractors. Hardcoded key is for demo only.
class AiDistractorService implements DistractorProvider {
  AiDistractorService({http.Client? client, String? model})
      : _client = client ?? http.Client(),
        // Default to the free tier model. Can be overridden via constructor.
        _model = model ?? 'gemini-2.5-flash-lite';

  static const String _apiKey = 'AIzaSyAFUztKCdx1fVCHW8DanryPeaArP09jwyw';
  final String _model;
  final http.Client _client;

  Future<List<String>> generate({
    required String term,
    required String answer,
  }) async {
    _assertKey();

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/models/$_model:generateContent?key=$_apiKey',
    );

    final prompt = '''
You read all questions and correct answers before generating. Produce exactly 3 plausible distractors for this multiple-choice flashcard.
Term: "$term"
Correct answer: "$answer"
Rules:
- Keep distractors in the same language as the term/answer.
- Make them relevant to the concept, similar in length to the correct answer, and challenging but still plausible.
- They must be factually correct on their own, but not the correct answer for this term.
- Must be unique and not equal to or a substring/superstring of the correct answer.
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
      throw Exception(
        'AI error ${response.statusCode}: ${response.body}. '
        'Model: $_model. Try gemini-pro or gemini-1.5-pro-latest if 404 persists.',
      );
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
  @override
  Future<Map<String, List<String>>> generateBatch(List<DeckCard> cards) async {
    _assertKey();
    if (cards.isEmpty) return {};

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/models/$_model:generateContent?key=$_apiKey',
    );

    final buffer = StringBuffer();
    buffer.writeln('You are a generator of distractors. Read and consider ALL items (questions and answers) before generating.');
    buffer.writeln('For each item, return exactly 3 distractors in the same language as the term/answer.');
    buffer.writeln('Make distractors relevant, similar in length to the correct answer, challenging but plausible, and factually correct on their own.');
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
      throw Exception(
        'AI error ${response.statusCode}: ${response.body}. '
        'Model: $_model. Try gemini-pro or gemini-1.5-pro-latest if 404 persists.',
      );
    }

    final decoded = jsonDecode(response.body);
    final rawText = decoded['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    if (rawText == null || rawText.isEmpty) {
      throw Exception('Empty AI response: $decoded');
    }

    final parsedArray = _decodeJsonArray(rawText);

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
      parsedJson = _decodeJsonObject(rawText);
    } on FormatException catch (e) {
      throw FormatException('AI response is not valid JSON: ${e.message}');
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

  List<dynamic> _decodeJsonArray(String rawText) {
    final sanitized = _sanitizeJsonLike(rawText, preferArray: true);
    try {
      final decoded = jsonDecode(sanitized);
      if (decoded is List) return decoded;
    } catch (_) {
      // Fall through to throw below.
    }
    throw FormatException('Could not parse array payload. Snippet: ${_shorten(rawText)}');
  }

  Map<String, dynamic> _decodeJsonObject(String rawText) {
    final sanitized = _sanitizeJsonLike(rawText, preferArray: false);
    try {
      final decoded = jsonDecode(sanitized);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Fall through to throw below.
    }
    throw FormatException('Could not parse object payload. Snippet: ${_shorten(rawText)}');
  }

  String _sanitizeJsonLike(String rawText, {required bool preferArray}) {
    // Handle fenced code blocks and extra explanations from the model.
    final fenced = RegExp(r'```(?:json)?\s*([\s\S]*?)```', multiLine: true);
    final fenceMatch = fenced.firstMatch(rawText);
    var text = (fenceMatch != null ? fenceMatch.group(1) : rawText) ?? rawText;
    text = text.trim();

    // If the model prepends explanations, slice out the JSON-looking part.
    final start = preferArray ? text.indexOf('[') : text.indexOf('{');
    final end = preferArray ? text.lastIndexOf(']') : text.lastIndexOf('}');
    if (start != -1 && end > start) {
      text = text.substring(start, end + 1);
    }

    // Remove trailing commas that Gemini sometimes leaves behind.
    final trailingCommaPattern = RegExp(r',(\s*[}\]])');
    text = text.replaceAllMapped(trailingCommaPattern, (m) => m.group(1)!);

    return text;
  }

  String _shorten(String input, {int max = 160}) {
    if (input.length <= max) return input;
    return '${input.substring(0, max)}...';
  }
}
