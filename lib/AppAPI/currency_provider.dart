import 'package:money_tracker/AppAPI/currency_services.dart';
import 'package:money_tracker/AppAPI/currency.dart';

class CurrencyProvider {
  // Singleton Pattern: Only one instance exists for the whole app
  static final CurrencyProvider _instance = CurrencyProvider._internal();
  factory CurrencyProvider() => _instance;
  CurrencyProvider._internal();

  Currency? rates;
  String currentCurrency = 'HKD'; // Global selected currency
  bool isLoaded = false;

  // Fetch once when the app starts
  Future<void> init() async {
    rates = await RemoteService().get();
    if (rates != null) isLoaded = true;
  }

  // The Abstract "Converter" Method
  String convert(double amount, String fromCurrency) {
    if (!isLoaded || rates == null || !rates!.data.containsKey(fromCurrency) || !rates!.data.containsKey(currentCurrency)) {
      return "${amount.toStringAsFixed(2)} $fromCurrency";
    }

    // Math: (Amount / base_rate) * target_rate
    double converted = (amount / rates!.data[fromCurrency]!) * rates!.data[currentCurrency]!;
    return "${converted.toStringAsFixed(2)} $currentCurrency";
  }

  double convertNum(double amount, String fromCurrency){
    if (!isLoaded || rates == null || !rates!.data.containsKey(fromCurrency) || !rates!.data.containsKey(currentCurrency)) {
      return amount;
    }
    double converted = (amount / rates!.data[fromCurrency]!) * rates!.data[currentCurrency]!;
    return converted;
  }

  List<String> currencies = ['HKD', 'USD', 'EUR', 'JPY'];

  // Method to toggle to the next currency
  void toggleCurrency() {
    int currentIndex = currencies.indexOf(currentCurrency);
    currentCurrency = currencies[(currentIndex + 1) % currencies.length];
  }
}