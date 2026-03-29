import 'dart:convert';

Currency currencyFromJson(String str) => Currency.fromJson(json.decode(str));

String currencyToJson(Currency data) => json.encode(data.toJson());

class Currency {
  Map<String, double> data;

  Currency({
    required this.data,
  });

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
    data: Map.from(json["data"]).map((k, v) => MapEntry<String, double>(k, v?.toDouble())),
  );

  Map<String, dynamic> toJson() => {
    "data": Map.from(data).map((k, v) => MapEntry<String, dynamic>(k, v)),
  };
}
