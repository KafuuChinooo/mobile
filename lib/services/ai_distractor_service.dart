import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flash_card/model/deck.dart';
import 'package:flash_card/services/distractor_provider.dart';

class AiDistractorService implements DistractorProvider {
  AiDistractorService({http.Client? client}) : _client = client ?? http.Client();

  static const String _apiKey = 'AIzaSyBIsETq9CTNcM6wSMHuLujvAgCQblWR_A0';
  static const String _model = 'gemma-3-27b-it';

  final http.Client _client;

  Future<List<String>> generate({
    required String term,
    required String answer,
  }) async {
    final batch = await generateBatch([
      DeckCard(term: term, definition: answer, id: 'single'),
    ]);
    final list = batch['single'];
    if (list == null || list.length < 3) {
      throw Exception('Not enough valid distractors for single request: $list');
    }
    return list.take(3).toList();
  }

  @override
  Future<Map<String, List<String>>> generateBatch(List<DeckCard> cards) async {
    if (cards.isEmpty) return {};

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    final items = cards
        .map((c) => {
              'id': c.id,
              'term': c.term,
              'answer': c.definition,
            })
        .toList();

    final prompt = '''
You are generating distractors (plausible wrong answers) for flashcards. Read each item and return JSON only, following the example structure exactly.
Strict rules:
- Output: JSON only, no markdown fences, no leading/trailing text.
- Structure example (copy this shape):
{"results":[{"id":"card1","distractors":["Đáp án sai 1","Đáp án sai 2","Đáp án sai 3"]},{"id":"card2","distractors":["Sai 1","Sai 2","Sai 3"]}]}
- Per item: exactly 3 concise, plausible, unique distractors.
- Safety: never match, paraphrase, or contain the correct answer; keep language consistent with the item.
Items: ${jsonEncode(items)}
''';

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

    final parsedJson = _parseJsonBlock(rawText);
    final results = parsedJson['results'];
    if (results is! List) {
      throw FormatException('AI response missing results array: $rawText');
    }

    final map = <String, List<String>>{};
    for (final entry in results) {
      if (entry is! Map) continue;
      final id = entry['id']?.toString() ?? '';
      final rawList = (entry['distractors'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final cleaned = <String>[];
      for (final item in rawList) {
        final trimmed = item.trim();
        if (trimmed.isEmpty) continue;
        final answer = cards.firstWhere((c) => c.id == id, orElse: () => DeckCard(term: '', definition: '', id: id)).definition;
        if (_equalsOrContains(trimmed, answer)) continue;
        if (cleaned.contains(trimmed)) continue;
        cleaned.add(trimmed);
      }
      if (id.isNotEmpty && cleaned.length >= 3) {
        map[id] = cleaned.take(3).toList();
      }
    }

    if (map.isEmpty) {
      throw Exception('No valid distractors returned: $rawText');
    }
    return map;
  }

  void dispose() {
    _client.close();
  }

  bool _equalsOrContains(String a, String b) {
    final la = a.toLowerCase();
    final lb = b.toLowerCase();
    return la == lb || la.contains(lb) || lb.contains(la);
  }

  Map<String, dynamic> _parseJsonBlock(String rawText) {
    // Try fenced code block first
    final fenced = RegExp(r'```(?:json)?\s*([\s\S]*?)```', multiLine: true);
    final fenceMatch = fenced.firstMatch(rawText);
    var text = (fenceMatch != null ? fenceMatch.group(1) : rawText) ?? rawText;
    text = text.trim();

    // Strip common leading markers like "json" or quoted wrappers
    text = text.replaceFirst(RegExp(r'''^["']?\s*json["']?:?''', caseSensitive: false), '').trim();

    // Trim to first/last brace if present
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end > start) {
      text = text.substring(start, end + 1);
    }

    // Remove wrapping quotes if the whole payload is quoted
    if (text.startsWith('"') && text.endsWith('"') && text.length > 1) {
      text = text.substring(1, text.length - 1);
    }

    // First try strict JSON
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {/* fallthrough */}

    // Retry with a lenient pass: replace single quotes with double quotes and decode again.
    var sanitized = text.replaceAll("'", '"');
    try {
      final decoded = jsonDecode(sanitized);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {/* fallthrough */}

    // If the model returned escaped JSON inside a string, try unescaping once.
    try {
      final decodedString = jsonDecode('"${sanitized.replaceAll('"', r'\\"')}"') as String;
      final innerStart = decodedString.indexOf('{');
      final innerEnd = decodedString.lastIndexOf('}');
      if (innerStart != -1 && innerEnd > innerStart) {
        final inner = decodedString.substring(innerStart, innerEnd + 1);
        final decoded = jsonDecode(inner);
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (_) {/* fallthrough */}

    // Last resort: manual extraction of entries like 'id':'...','distractors':[...]
    final entries = <Map<String, dynamic>>[];
    final entryRe = RegExp(r"'id'\s*:\s*'([^']+)'.*?'distractors'\s*:\s*\[(.*?)\]", dotAll: true);
    for (final match in entryRe.allMatches(text)) {
      final id = match.group(1);
      final rawList = match.group(2) ?? '';
      final parts = rawList.split(RegExp(r'\s*,\s*')).map((e) {
        var v = e.trim();
        if (v.startsWith("'") && v.endsWith("'")) {
          v = v.substring(1, v.length - 1);
        } else if (v.startsWith('"') && v.endsWith('"')) {
          v = v.substring(1, v.length - 1);
        }
        return v;
      }).where((v) => v.isNotEmpty).toList();
      if (id != null && id.isNotEmpty && parts.length >= 3) {
        entries.add({'id': id, 'distractors': parts});
      }
    }
    if (entries.isNotEmpty) {
      return {'results': entries};
    }

    throw FormatException('AI response is not valid JSON: $rawText');
  }
}
