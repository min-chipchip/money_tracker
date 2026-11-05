/// Starting values for currencies people often add, so the "Add currency"
/// sheet can fill itself in. Everything here can be edited before saving.
///
/// `approxPerUsd` ("1 USD = x") is a rough, hand-picked value, NOT a live
/// rate: it only has to be close enough to convert until real rates are
/// downloaded (with FX_API_KEY set) or the user types a better one.
class CurrencyPreset {
  const CurrencyPreset(this.code, this.name, this.symbol, this.exponent, this.approxPerUsd);

  final String code;
  final String name;
  final String symbol;

  /// Decimal places used in everyday prices (VND, KRW and IDR use none).
  final int exponent;
  final double approxPerUsd;
}

const currencyPresets = <CurrencyPreset>[
  CurrencyPreset('VND', 'Vietnamese dong', '₫', 0, 25400),
  CurrencyPreset('GBP', 'British pound', '£', 2, 0.79),
  CurrencyPreset('CNY', 'Chinese yuan', '¥', 2, 7.2),
  CurrencyPreset('SGD', 'Singapore dollar', r'S$', 2, 1.34),
  CurrencyPreset('TWD', 'Taiwan dollar', r'NT$', 2, 32),
  CurrencyPreset('KRW', 'South Korean won', '₩', 0, 1380),
  CurrencyPreset('THB', 'Thai baht', '฿', 2, 35),
  CurrencyPreset('MYR', 'Malaysian ringgit', 'RM', 2, 4.5),
  CurrencyPreset('PHP', 'Philippine peso', '₱', 2, 57),
  CurrencyPreset('IDR', 'Indonesian rupiah', 'Rp', 0, 16000),
  CurrencyPreset('INR', 'Indian rupee', '₹', 2, 84),
  CurrencyPreset('CAD', 'Canadian dollar', r'C$', 2, 1.37),
  CurrencyPreset('NZD', 'New Zealand dollar', r'NZ$', 2, 1.68),
  CurrencyPreset('CHF', 'Swiss franc', 'CHF', 2, 0.88),
  CurrencyPreset('MOP', 'Macanese pataca', 'MOP', 2, 8.0),
];

CurrencyPreset? presetFor(String code) =>
    currencyPresets.where((p) => p.code == code.toUpperCase()).firstOrNull;
