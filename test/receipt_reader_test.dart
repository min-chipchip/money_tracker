import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:money_tracker/AppAPI/receipt_reader.dart';

/// Wraps [answer] the way the Gemini generateContent API returns it.
String geminiResponse(Object answer) => jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': answer is String ? answer : jsonEncode(answer)},
            ],
          },
        },
      ],
    });

void main() {
  group('GeminiReceiptReader.parseResponse', () {
    test('reads a normal receipt', () {
      final r = GeminiReceiptReader.parseResponse(geminiResponse({
        'merchant': 'Highlands Coffee',
        'date': '2026-11-05',
        'currency': 'vnd',
        'total': 181440,
        'category': 'Food',
        'items': [
          {'name': 'Phin Sua Da x2', 'amount': 78000},
          {'name': 'Banh Mi Thit', 'amount': 35000},
        ],
      }));
      expect(r.merchant, 'Highlands Coffee');
      expect(r.date, DateTime(2026, 11, 5));
      expect(r.currency, 'VND');
      expect(r.total, 181440);
      expect(r.category, 'Food');
      expect(r.items.map((i) => i.name), ['Phin Sua Da x2', 'Banh Mi Thit']);
    });

    test('drops values that make no sense instead of trusting them', () {
      final r = GeminiReceiptReader.parseResponse(geminiResponse({
        'merchant': '  ',
        'date': '2999-01-01',
        'currency': 'dollars',
        'total': 12.5,
        'items': [
          {'name': 'Refund', 'amount': -3},
          {'name': '', 'amount': 4},
        ],
      }));
      expect(r.merchant, isNull);
      expect(r.date, isNull);
      expect(r.currency, isNull);
      expect(r.total, 12.5);
      expect(r.items, isEmpty);
    });

    test('fails clearly when there is no total (e.g. not a receipt)', () {
      expect(
        () => GeminiReceiptReader.parseResponse(geminiResponse(<String, Object>{})),
        throwsA(isA<ReceiptReadException>().having((e) => e.message, 'message', contains('total'))),
      );
    });

    test('fails clearly on malformed responses', () {
      expect(() => GeminiReceiptReader.parseResponse('not json'), throwsA(isA<ReceiptReadException>()));
      expect(() => GeminiReceiptReader.parseResponse(jsonEncode({'candidates': []})), throwsA(isA<ReceiptReadException>()));
      expect(() => GeminiReceiptReader.parseResponse(geminiResponse('{oops')), throwsA(isA<ReceiptReadException>()));
    });
  });

  group('GeminiReceiptReader.read', () {
    late File image;
    setUp(() {
      final dir = Directory.systemTemp.createTempSync('reader_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      image = File('${dir.path}/r.jpg')..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xD9]);
    });

    /// A client that answers with [statuses] in order and records which
    /// model each call went to.
    (GeminiReceiptReader, List<String>) readerAnswering(List<int> statuses) {
      final calls = <String>[];
      final client = MockClient((req) async {
        final status = statuses[calls.length];
        calls.add(req.url.pathSegments.last.split(':').first);
        return http.Response(status == 200 ? geminiResponse({'total': 42}) : '{"error":{}}', status);
      });
      return (
        GeminiReceiptReader(client: client, apiKey: 'test-key'),
        calls,
      );
    }

    Future<ReceiptReading> read(GeminiReceiptReader r) =>
        r.read(image, categories: const ['Food'], fallbackCurrency: 'HKD');

    test('switches to the fallback model when the main one is busy', () async {
      final (reader, calls) = readerAnswering([503, 200]);
      expect((await read(reader)).total, 42);
      expect(calls, ['gemini-flash-latest', 'gemini-3.5-flash']);
    });

    test('switches to the fallback model when the main one is too slow', () async {
      final calls = <String>[];
      final reader = GeminiReceiptReader(
        apiKey: 'k',
        attemptTimeout: const Duration(milliseconds: 50),
        client: MockClient((req) async {
          calls.add(req.url.pathSegments.last.split(':').first);
          if (calls.length == 1) await Future<void>.delayed(const Duration(milliseconds: 300));
          return http.Response(geminiResponse({'total': 7}), 200);
        }),
      );
      expect((await read(reader)).total, 7);
      expect(calls, ['gemini-flash-latest', 'gemini-3.5-flash']);
    });

    test('gives up with a clear message when every model is busy', () async {
      final (reader, calls) = readerAnswering([503, 503]);
      await expectLater(
        read(reader),
        throwsA(isA<ReceiptReadException>().having((e) => e.message, 'message', contains('busy'))),
      );
      expect(calls, hasLength(2));
    });

    test('does not retry a rejected key', () async {
      final (reader, calls) = readerAnswering([403]);
      await expectLater(read(reader), throwsA(isA<ReceiptReadException>()));
      expect(calls, hasLength(1));
    });

    test('asks for low thinking to keep it fast', () async {
      late Map<String, dynamic> sent;
      final reader = GeminiReceiptReader(
        apiKey: 'k',
        client: MockClient((req) async {
          sent = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response(geminiResponse({'total': 1}), 200);
        }),
      );
      await read(reader);
      expect(sent['generationConfig']['thinkingConfig'], {'thinkingLevel': 'low'});
    });
  });

  test('schema limits category to the user\'s own categories', () {
    final schema = GeminiReceiptReader.responseSchema(['Food', 'Transport']);
    expect(schema['properties']['category']['enum'], ['Food', 'Transport']);
  });
}
