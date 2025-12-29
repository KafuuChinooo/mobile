import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AiVocabEntry {
  final String term;
  final String definition;

  AiVocabEntry({required this.term, required this.definition});

  factory AiVocabEntry.fromJson(Map<String, dynamic> json) {
    return AiVocabEntry(
      term: (json['term'] ?? '').toString(),
      definition: (json['definition'] ?? '').toString(),
    );
  }
}

class AiVocabScreen extends StatefulWidget {
  const AiVocabScreen({super.key});

  @override
  State<AiVocabScreen> createState() => _AiVocabScreenState();
}

class _AiVocabScreenState extends State<AiVocabScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _countController = TextEditingController(text: '10');
  final TextEditingController _languageController = TextEditingController(text: 'Vietnamese');
  bool _loading = false;
  List<AiVocabEntry> _results = [];
  static const String _apiKey = 'AIzaSyBIsETq9CTNcM6wSMHuLujvAgCQblWR_A0';
  static const String _model = 'gemma-3-27b-it';

  @override
  void dispose() {
    _textController.dispose();
    _countController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final text = _textController.text.trim();
    final desired = int.tryParse(_countController.text.trim());
    final language = _languageController.text.trim().isEmpty ? 'English' : _languageController.text.trim();
    if (text.isEmpty || desired == null || desired <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste text and enter desired count')),
      );
      return;
    }
    final wordCount = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final charCount = text.replaceAll(RegExp(r'\s+'), '').runes.length;
    final effectiveCount = wordCount >= 50 ? wordCount : charCount;
    if (effectiveCount < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content must have at least ~50 words/characters')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _results = [];
    });

    try {
      final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey');
      final prompt = _buildPrompt(text, desired, language);
      final response = await http.post(
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
        throw Exception('Empty AI response');
      }

      final entries = _parseEntries(rawText);
      setState(() {
        _results = entries;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _buildPrompt(String text, int desired, String language) {
    final limited = desired.clamp(1, 30);
    return '''
Extract exactly $limited important vocabulary items from the text below.
Return ONLY valid JSON in this schema:
{"vocab":[{"term":"word or phrase","definition":"short meaning in $language"}]}
Rules:
- Terms follow the source language; pick challenging/academic words or phrases.
- Definitions concise (<=25 words), translated into $language.
- Avoid duplicates; no markdown.
Text:
$text
''';
  }

  List<AiVocabEntry> _parseEntries(String raw) {
    // Try to isolate JSON block.
    var text = raw.trim();
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end > start) {
      text = text.substring(start, end + 1);
    }
    try {
      final decoded = jsonDecode(text);
      final list = decoded['vocab'];
      if (list is List) {
        return list.map((e) => AiVocabEntry.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      // fallback below
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Vocabulary Generator'),
        actions: [
          if (_results.isNotEmpty)
            TextButton(
              onPressed: _loading ? null : _useResults,
              child: const Text('Use', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste text (>=50 words) to extract vocabulary.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              minLines: 8,
              maxLines: 12,
              decoration: const InputDecoration(
                hintText: 'Paste your passage here...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _countController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Number of words',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _languageController,
                    decoration: const InputDecoration(
                      labelText: 'Target language',
                      hintText: 'e.g., Vietnamese, English, Japanese',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _generate,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_fix_high),
                  label: const Text('Generate'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('No results yet'))
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _results[index];
                        return ListTile(
                          title: Text(item.term),
                          subtitle: Text(item.definition),
                        );
                      },
                    ),
            ),
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _useResults,
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('Add to deck'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _generate,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Find other words'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _useResults() {
    Navigator.of(context).pop(_results);
  }
}
