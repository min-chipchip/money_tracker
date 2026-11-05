import 'package:money_tracker/AppAPI/currency.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Pass the key at build time; never commit it:
//   flutter run --dart-define=FX_API_KEY=your_key_here
const String _apiKey = String.fromEnvironment('FX_API_KEY');

class RemoteService {
  Future<Currency?> get() async {
    if (_apiKey.isEmpty) {
      debugPrint("FX_API_KEY not set - skipping currency fetch");
      return null;
    }
    try {
      var uri = Uri.https('api.freecurrencyapi.com', '/v1/latest', {
        'apikey': _apiKey,
      });
      // Adding headers often helps resolve 403 errors in emulator environments
      var response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App',
      });

      debugPrint("Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        return currencyFromJson(response.body);
      } else {
        debugPrint("Server returned an error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Exception during API call: $e");
    }

    debugPrint("Returning null - API fetch failed");
    return null;
  }
}