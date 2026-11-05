import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Gemini settings, passed at build time like FX_API_KEY:
//   flutter run --dart-define=GEMINI_API_KEY=your_key_here
// Optional: --dart-define=GEMINI_MODEL=<model id> to pin a model, and
// --dart-define=GEMINI_FALLBACK_MODEL=<model id> for the one tried when the
// main model stays overloaded (503).
//
// DEV ONLY: a key compiled into the app can be extracted from it. Before
// releasing, move this call behind a backend (or Firebase AI Logic with
// App Check) so the key never ships.
const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
const String _model = String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-flash-latest');
const String _fallbackModel = String.fromEnvironment('GEMINI_FALLBACK_MODEL', defaultValue: 'gemini-3.5-flash');

/// One line on the receipt.
class ReceiptLine {
  const ReceiptLine(this.name, this.amount);
  final String name;
  final double amount;
}

/// What the AI read off a receipt. Every field may be missing: the user
/// checks and corrects it in the transaction form before saving.
class ReceiptReading {
  const ReceiptReading({
    this.merchant,
    this.date,
    this.currency,
    this.total,
    this.category,
    this.items = const [],
  });

  final String? merchant;
  final DateTime? date;

  /// ISO 4217 code, upper case (e.g. "VND").
  final String? currency;

  /// Amount paid, in major units (181440 VND, 12.5 HKD).
  final double? total;

  /// One of the category names that were offered to the model.
  final String? category;
  final List<ReceiptLine> items;

  /// Parses the model's JSON, dropping anything that doesn't make sense
  /// rather than trusting it.
  factory ReceiptReading.fromJson(Map<String, dynamic> j) {
    String? str(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;
    double? num_(Object? v) => v is num && v.isFinite && v > 0 ? v.toDouble() : null;

    final currency = str(j['currency'])?.toUpperCase();
    final date = DateTime.tryParse(str(j['date']) ?? '');
    final now = DateTime.now();
    return ReceiptReading(
      merchant: str(j['merchant']),
      // A receipt from the future, or decades ago, is a misread.
      date: date != null && date.isBefore(now.add(const Duration(days: 1))) && date.year >= 2000 ? date : null,
      currency: currency != null && RegExp(r'^[A-Z]{3}$').hasMatch(currency) ? currency : null,
      total: num_(j['total']),
      category: str(j['category']),
      items: [
        for (final it in (j['items'] as List? ?? const []))
          if (it is Map && str(it['name']) != null && num_(it['amount']) != null)
            ReceiptLine(str(it['name'])!, num_(it['amount'])!),
      ],
    );
  }
}

class ReceiptReadException implements Exception {
  const ReceiptReadException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Sends a receipt photo to Gemini and gets structured data back.
class GeminiReceiptReader {
  const GeminiReceiptReader({
    http.Client? client,
    @visibleForTesting String? apiKey,
    this.attemptTimeout = const Duration(seconds: 45),
  })  : _client = client,
        _keyOverride = apiKey;
  final http.Client? _client;
  final String? _keyOverride;

  /// How long to wait for one model before trying the next one. The last
  /// model gets twice as long, since there is nothing left to fall back to.
  final Duration attemptTimeout;

  String get _key => _keyOverride ?? _apiKey;

  static bool get isConfigured => _apiKey.isNotEmpty;

  /// [categories] are the user's expense category names; the model must
  /// pick one of them. [fallbackCurrency] is used when the receipt shows
  /// no currency.
  Future<ReceiptReading> read(
    File image, {
    required List<String> categories,
    required String fallbackCurrency,
  }) async {
    if (_key.isEmpty) {
      throw const ReceiptReadException('GEMINI_API_KEY is not set. Run the app with --dart-define=GEMINI_API_KEY=...');
    }

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'inline_data': {'mime_type': 'image/jpeg', 'data': base64Encode(await image.readAsBytes())},
            },
            {'text': buildPrompt(categories: categories, fallbackCurrency: fallbackCurrency)},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0,
        'responseMimeType': 'application/json',
        'responseSchema': responseSchema(categories),
        // Reading a receipt needs little reasoning; low thinking answers faster.
        'thinkingConfig': {'thinkingLevel': 'low'},
      },
    });

    // When the main model is overloaded (busy or too slow), try the fallback
    // model instead of waiting on the same one again.
    final models = [
      _model,
      if (_fallbackModel.isNotEmpty && _fallbackModel != _model) _fallbackModel,
    ];
    final client = _client ?? http.Client();
    try {
      for (var i = 0;; i++) {
        final model = models[i];
        final last = i == models.length - 1;
        final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent');
        final watch = Stopwatch()..start();
        final http.Response res;
        try {
          res = await client
              .post(uri, headers: {'Content-Type': 'application/json', 'x-goog-api-key': _key}, body: body)
              .timeout(last ? attemptTimeout * 2 : attemptTimeout);
        } on SocketException {
          throw const ReceiptReadException('No internet connection.');
        } on TimeoutException {
          debugPrint('Gemini $model timed out after ${watch.elapsed.inSeconds}s');
          if (!last) continue;
          throw const ReceiptReadException('Gemini is taking too long right now. Try again in a few minutes.');
        } on Exception catch (e) {
          throw ReceiptReadException('Could not reach Gemini: $e');
        }

        debugPrint('Gemini $model answered ${res.statusCode} in ${watch.elapsed.inSeconds}s');
        if (res.statusCode == 200) return parseResponse(res.body);
        debugPrint(res.body);
        final busy = const {500, 502, 503}.contains(res.statusCode);
        if (busy && !last) continue;
        throw ReceiptReadException(switch (res.statusCode) {
          400 || 403 => 'Gemini rejected the request. Check GEMINI_API_KEY and GEMINI_MODEL.',
          404 => 'Gemini model "$model" not found. Set GEMINI_MODEL to a current model id.',
          429 => 'Gemini rate limit reached. Try again in a minute.',
          _ when busy => 'Gemini is busy right now. Try again in a few minutes.',
          _ => 'Gemini error ${res.statusCode}.',
        });
      }
    } finally {
      if (_client == null) client.close();
    }
  }

  @visibleForTesting
  static String buildPrompt({required List<String> categories, required String fallbackCurrency}) => '''
You read shop receipts for a personal expense tracker.
Extract from the receipt image:
- merchant: the shop or restaurant name.
- date: purchase date as YYYY-MM-DD. Receipts may use day/month/year order.
- currency: ISO 4217 code of the amounts. If the receipt does not show it, use $fallbackCurrency.
- total: the final amount paid, including tax and tip, as a plain number with no thousands separators.
- category: the best match from this list: ${categories.join(', ')}.
- items: each purchased line with its amount.
If something is unreadable, leave it out instead of guessing.
If the image is not a receipt, return an empty object.''';

  @visibleForTesting
  static Map<String, dynamic> responseSchema(List<String> categories) => {
        'type': 'OBJECT',
        'properties': {
          'merchant': {'type': 'STRING'},
          'date': {'type': 'STRING', 'description': 'YYYY-MM-DD'},
          'currency': {'type': 'STRING', 'description': 'ISO 4217 code'},
          'total': {'type': 'NUMBER'},
          'category': {'type': 'STRING', 'enum': categories},
          'items': {
            'type': 'ARRAY',
            'items': {
              'type': 'OBJECT',
              'properties': {
                'name': {'type': 'STRING'},
                'amount': {'type': 'NUMBER'},
              },
              'required': ['name', 'amount'],
            },
          },
        },
      };

  @visibleForTesting
  static ReceiptReading parseResponse(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final parts = decoded['candidates']?[0]?['content']?['parts'] as List?;
      final text = parts?.whereType<Map>().map((p) => p['text']).whereType<String>().join();
      if (text == null || text.isEmpty) {
        throw const ReceiptReadException('Gemini returned no answer for this image.');
      }
      final reading = ReceiptReading.fromJson(jsonDecode(text) as Map<String, dynamic>);
      if (reading.total == null) {
        throw const ReceiptReadException("Couldn't find a total on this receipt. Try a clearer photo.");
      }
      return reading;
    } on ReceiptReadException {
      rethrow;
    } on Object {
      throw const ReceiptReadException('Gemini returned something unexpected. Try again.');
    }
  }
}
