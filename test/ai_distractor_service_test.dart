import 'dart:convert';

import 'package:flash_card/model/deck.dart';
import 'package:flash_card/services/ai_distractor_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AiDistractorService', () {
    test('generateBatch parses fenced JSON with trailing commas', () async {
      final mockClient = MockClient((request) async {
        final body = jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': '```json\n'
                        '[{"id":"1","distractors":["Sai 1","Sai 2","Sai 3",]},'
                        '{"id":"2","distractors":["Lua 1","Lua 2","Lua 3"],},]'
                        '\n```'
                  }
                ]
              }
            }
          ]
        });
        return http.Response(body, 200);
      });

      final service = AiDistractorService(client: mockClient, model: 'test-model');

      final cards = [
        DeckCard(id: '1', term: 't1', definition: 'Dap an 1'),
        DeckCard(id: '2', term: 't2', definition: 'Dap an 2'),
      ];

      final result = await service.generateBatch(cards);

      expect(result['1'], ['Sai 1', 'Sai 2', 'Sai 3']);
      expect(result['2'], ['Lua 1', 'Lua 2', 'Lua 3']);
    });
  });
}
