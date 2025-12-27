import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flash_card/services/quiz_engine.dart';

/// Simple Gemini-based hint generator for quiz answers.
class AiHintService {
  AiHintService({http.Client? client, String? model})
    : _client = client ?? http.Client(),
      _model = model ?? 'gemma-3-27b-it'; // align with question/distractor model

  static const String _apiKey = 'AIzaSyBIsETq9CTNcM6wSMHuLujvAgCQblWR_A0';
  final String _model;
  final http.Client _client;

  Future<String> generateHint({
    required String term,
    required String answer,
  }) async {
    _assertKey();

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    final prompt = '''
You are generating a single concise hint for a quiz flashcard. Read the term and the correct answer, then return only JSON that matches the shape in the example below.
Term: "$term"
Correct answer: "$answer"
Strict rules:
- Language: match the language of the term/answer.
- Safety: never reveal the exact answer text or spell it out.
- Brevity: exactly one short sentence.
- Format: respond with JSON only, no markdown fences, no leading/trailing text.
JSON example (structure to follow):
{"hint":"Gợi ý ngắn gọn và gián tiếp ở đây"}
Return exactly one object with the field "hint".''';

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('AI hint error ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final rawText = decoded['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    if (rawText == null || rawText.isEmpty) {
      throw Exception('Empty AI hint response: $decoded');
    }

    return _parseHint(rawText);
  }

  String _parseHint(String rawText) {
    final fenced = RegExp(r'```(?:json)?\\s*([\\s\\S]*?)```', multiLine: true);
    final fenceMatch = fenced.firstMatch(rawText);
    var text = (fenceMatch != null ? fenceMatch.group(1) : rawText) ?? rawText;
    text = text.trim();

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end > start) {
      text = text.substring(start, end + 1);
    }

    try {
      final decoded = jsonDecode(text);
      final hint = decoded['hint']?.toString();
      if (hint != null && hint.trim().isNotEmpty) return hint.trim();
    } catch (_) {
      // ignore and fall through
    }

    // Fallback: return first sentence-ish chunk.
    final firstLine = rawText.split(RegExp(r'[\\n\\r]')).first.trim();
    return firstLine.isNotEmpty ? firstLine : 'No hint available.';
  }

  void dispose() {
    _client.close();
  }

  /// Batch hint generation to reduce API calls. Returns map of cardId -> hint.
  Future<Map<String, String>> generateHintsBatch(List<QuizQuestion> questions) async {
    if (questions.isEmpty) return {};

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    final items = questions
        .map((q) => {'id': q.cardId, 'term': q.term, 'answer': q.correctAnswer})
        .toList();

    final prompt = '''
You are generating concise hints for multiple quiz flashcards. Read each item, then return only JSON that matches the structure in the example below.
Strict rules:
- Language: match the language of each term/answer.
- Safety: never reveal the exact answer text or spell it out.
- Brevity: each hint is one short sentence.
- Format: respond with JSON only, no markdown fences, no leading/trailing text.
JSON example (structure to follow):
{"results":[{"id":"card1","hint":"Gợi ý ngắn gọn và gián tiếp cho card1"},{"id":"card2","hint":"Gợi ý ngắn gọn và gián tiếp cho card2"}]}
Items: ${jsonEncode(items)}
''';

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('AI hint error ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final rawText = decoded['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    if (rawText == null || rawText.isEmpty) {
      throw Exception('Empty AI hint response: $decoded');
    }

    final map = <String, String>{};
    try {
      final parsed = jsonDecode(_extractJson(rawText));
      final results = parsed['results'];
      if (results is List) {
        for (final entry in results) {
          if (entry is! Map) continue;
          final id = entry['id']?.toString();
          final hint = entry['hint']?.toString();
          if (id != null && id.isNotEmpty && hint != null && hint.trim().isNotEmpty) {
            map[id] = hint.trim();
          }
        }
      }
    } catch (_) {
      // Fallback: try to parse single hint (unlikely to succeed for batch).
    }

    if (map.isEmpty) {
      throw FormatException('AI hint batch response is not valid JSON: $rawText');
    }

    return map;
  }

  String _extractJson(String rawText) {
    final fenced = RegExp(r'```(?:json)?\\s*([\\s\\S]*?)```', multiLine: true);
    final fenceMatch = fenced.firstMatch(rawText);
    var text = (fenceMatch != null ? fenceMatch.group(1) : rawText) ?? rawText;
    text = text.trim();
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end > start) {
      text = text.substring(start, end + 1);
    }
    return text;
  }

  void _assertKey() {
    if (_apiKey.isEmpty || _apiKey == 'PUT_YOUR_API_KEY_HERE') {
      throw StateError('Set your Gemini API key in AiHintService._apiKey before calling generateHint.');
    }
  }
}
