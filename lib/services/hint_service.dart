import 'dart:convert';

import 'package:http/http.dart' as http;

/// Simple Gemini-based hint generator for quiz answers.
class AiHintService {
  AiHintService({http.Client? client, String? model})
    : _client = client ?? http.Client(),
      _model = model ?? 'gemini-2.5-flash-lite';

  static const String _apiKey = 'AIzaSyAFUztKCdx1fVCHW8DanryPeaArP09jwyw';
  final String _model;
  final http.Client _client;

  Future<String> generateHint({
    required String term,
    required String answer,
  }) async {
    _assertKey();

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/models/$_model:generateContent?key=$_apiKey',
    );

    final prompt =
        '''
You are creating a brief hint for a quiz. Read the term and correct answer, then produce a concise, indirect hint that helps a learner recall the correct answer without stating it explicitly.
Term: "$term"
Correct answer: "$answer"
Rules:
- Keep the hint in the same language as the term/answer.
- Do NOT reveal the exact answer text.
- Keep it short (one sentence).
Return JSON only: {"hint":"<hint>"}''';

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

  void _assertKey() {
    if (_apiKey.isEmpty || _apiKey == 'PUT_YOUR_API_KEY_HERE') {
      throw StateError('Set your Gemini API key in AiHintService._apiKey before calling generateHint.');
    }
  }
}
