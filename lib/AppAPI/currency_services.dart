import 'package:money_tracker/AppAPI/currency.dart';
import 'package:http/http.dart' as http;

class RemoteService {
  Future<Currency?> get() async {
    try {
      var uri = Uri.https('api.freecurrencyapi.com', '/v1/latest', {
        'apikey': 'fca_live_7jY3TQ47tpIJNUiBQl3ha2GK31n4wkyIVQyw6Rfo',
      });
      // Adding headers often helps resolve 403 errors in emulator environments
      var response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Flutter-App',
      });

      print("Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        return currencyFromJson(response.body);
      } else {
        print("Server returned an error: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception during API call: $e");
    }

    print("Returning null - API fetch failed");
    return null;
  }
}