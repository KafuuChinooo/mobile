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
    List<DeckCard>? deckContext,
    String? deckTitle,
    String? deckDescription,
    List<String>? deckTags,
    String? deckCategory,
  }) async {
    final singleCard = DeckCard(term: term, definition: answer, id: 'single');
    final batch = await generateBatch(
      [singleCard],
      deckContext: deckContext ?? [singleCard],
      deckTitle: deckTitle,
      deckDescription: deckDescription,
      deckTags: deckTags,
      deckCategory: deckCategory,
    );
    final list = batch['single'];
    if (list == null || list.length < 3) {
      throw Exception('Not enough valid distractors for single request: $list');
    }
    return list.take(3).toList();
  }

  @override
  Future<Map<String, List<String>>> generateBatch(
    List<DeckCard> cards, {
    List<DeckCard>? deckContext,
    String? deckTitle,
    String? deckDescription,
    List<String>? deckTags,
    String? deckCategory,
  }) async {
    if (cards.isEmpty) return {};
    final fallback = _fallbackDistractors(deckContext ?? cards);
    final items = cards
        .map((c) => {
              'id': c.id,
              'term': c.term,
              'answer': c.definition,
            })
        .toList();

    try {
      return await _requestAndParse(
        items: items,
        cards: cards,
        fullDeck: deckContext ?? cards,
        deckTitle: deckTitle,
        deckDescription: deckDescription,
        deckTags: deckTags,
        deckCategory: deckCategory,
        strict: false,
      );
    } on FormatException {
      // Retry once with a stricter prompt to avoid malformed JSON.
      try {
        return await _requestAndParse(
          items: items,
          cards: cards,
          fullDeck: deckContext ?? cards,
          deckTitle: deckTitle,
          deckDescription: deckDescription,
          deckTags: deckTags,
          deckCategory: deckCategory,
          strict: true,
        );
      } catch (_) {
        return fallback;
      }
    } catch (_) {
      // As a last resort, fall back to local generation to avoid breaking the game flow.
      return fallback;
    }
  }

  void dispose() {
    _client.close();
  }

  bool _equalsOrContains(String a, String b) {
    final la = a.toLowerCase();
    final lb = b.toLowerCase();
    return la == lb || la.contains(lb) || lb.contains(la);
  }

  Future<Map<String, List<String>>> _requestAndParse({
    required List<Map<String, String>> items,
    required List<DeckCard> cards,
    required List<DeckCard> fullDeck,
    String? deckTitle,
    String? deckDescription,
    List<String>? deckTags,
    String? deckCategory,
    required bool strict,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    final prompt = _buildPrompt(
      items,
      fullDeck: fullDeck,
      deckTitle: deckTitle,
      deckDescription: deckDescription,
      deckTags: deckTags,
      deckCategory: deckCategory,
      strict: strict,
    );

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
    dynamic results = parsedJson['results'];
    if (results is String) {
      try {
        final inner = jsonDecode(results);
        if (inner is Map && inner['results'] is List) {
          results = inner['results'];
        } else if (inner is List) {
          results = inner;
        }
      } catch (_) {
        // fall through
      }
    }
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

  String _buildPrompt(
    List<Map<String, String>> items, {
    required List<DeckCard> fullDeck,
    String? deckTitle,
    String? deckDescription,
    List<String>? deckTags,
    String? deckCategory,
    required bool strict,
  }) {
    final deckMeta = {
      'title': deckTitle,
      'description': deckDescription,
      'tags': deckTags,
      'category': deckCategory,
    };
    final deckCards = fullDeck
        .map((c) => {
              'id': c.id,
              'term': c.term,
              'answer': c.definition,
            })
        .toList();

    final base = '''
You are an expert exam item writer. Generate exactly 3 high-quality distractors (wrong answers) per flashcard.
Context to read carefully:
- Deck metadata: ${jsonEncode(deckMeta)}
- Full deck cards (use to avoid duplicates/near-misses): ${jsonEncode(deckCards)}
Rules (follow all):
- Treat "term" as the full prompt/question as given (may be long, multi-line, or complex); do NOT answer it, only create wrong answers.
- Match the style/length of the provided "answer" (back side/definition), not the term. If the answer is a sentence, your distractors should be sentence-like and similar in length/tone.
- Output VALID JSON only, one object, double quotes everywhere, no markdown/fences/prose.
- Schema: {"results":[{"id":"<id>","distractors":["d1","d2","d3"]},...]}
- Each "distractors" array: exactly 3 unique, concise, plausible wrong answers that fit the deck context and language. Never reveal or paraphrase the correct answer.
- Keep style consistent with the deck language; avoid gibberish, meta-comments, or explanations.
Format example (structure only):
{"results":[{"id":"card1","distractors":["Wrong A","Wrong B","Wrong C"]}]}
Items needing distractors: ${jsonEncode(items)}
''';

    if (!strict) return base;

    return '''
STRICT MODE: Return exactly one JSON object, nothing else. Use ONLY double quotes. Follow this schema exactly:
{"results":[{"id":"<id>","distractors":["d1","d2","d3"]},...]}
Rules to repeat to yourself:
- "term" may be complex/multi-line; keep it intact and DO NOT answer it.
- Style: mirror the provided "answer" style/length (definition/back side), not the term.
- No markdown, no fences, no single quotes, no comments, no leading/trailing text.
If you output anything else, the request fails.
Items needing distractors: ${jsonEncode(items)}
''';
  }

  Map<String, List<String>> _fallbackDistractors(List<DeckCard> cards) {
    // Simple non-AI fallback: use other card definitions as distractors.
    final map = <String, List<String>>{};
    for (final card in cards) {
      final wrongs = <String>[];
      final seen = <String>{};
      final correct = card.definition.toLowerCase();

      void addIfValid(String? value) {
        final trimmed = value?.trim();
        if (trimmed == null || trimmed.isEmpty) return;
        final lower = trimmed.toLowerCase();
        if (lower == correct) return;
        if (!seen.add(lower)) return;
        wrongs.add(trimmed);
      }

      for (final d in card.distractors ?? <String>[]) {
        addIfValid(d);
        if (wrongs.length >= 3) break;
      }
      for (final other in cards) {
        if (other.id == card.id) continue;
        addIfValid(other.definition);
        if (wrongs.length >= 3) break;
      }
      while (wrongs.length < 3) {
        addIfValid('Option ${wrongs.length + 1}');
      }
      map[card.id] = wrongs.take(3).toList();
    }
    return map;
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

    // If the whole payload is a JSON string with escaped quotes, attempt a direct decode.
    try {
      final direct = jsonDecode(text);
      if (direct is Map<String, dynamic>) return direct;
    } catch (_) {/* fallthrough */}

    // If "results" is returned as a single-quoted JSON string, extract and decode it.
    final resultsStringMatch = RegExp("\"results\"\\s*:\\s*'(\\[.*\\])'", dotAll: true).firstMatch(text);
    if (resultsStringMatch != null) {
      final rawList = resultsStringMatch.group(1);
      if (rawList != null) {
        try {
          final list = jsonDecode(rawList);
          if (list is List) {
            return {'results': list};
          }
        } catch (_) {
          // ignore and continue
        }
      }
    }

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
