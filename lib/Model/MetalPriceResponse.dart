class MetalPriceResponse {
  final bool success;
  final String base;
  final String startDate;
  final String endDate;
  final Map<String, Map<String, double>> rates;

  MetalPriceResponse({
    required this.success,
    required this.base,
    required this.startDate,
    required this.endDate,
    required this.rates,
  });

  factory MetalPriceResponse.fromJson(Map<String, dynamic> json) {
    return MetalPriceResponse(
      success: json['success'],
      base: json['base'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      rates: Map.from(json['rates']).map((key, value) {
        return MapEntry(
            key, Map.from(value).map((key, value) => MapEntry(key, value.toDouble())));
      }),
    );
  }
}
