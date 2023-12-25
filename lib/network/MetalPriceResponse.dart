class MetalPriceResponse {
  bool success;
  String base;
  String startDate;
  String endDate;
  Map<String, Map<String, double>> rates;

  MetalPriceResponse({
    required this.success,
    required this.base,
    required this.startDate,
    required this.endDate,
    required this.rates,
  });

  factory MetalPriceResponse.fromJson(Map<String, dynamic> json) {
    Map<String, Map<String, double>> rates = {};
    if (json['rates'] != null) {
      json['rates'].forEach((date, rate) {
        Map<String, double> currencyRates = {};
        rate.forEach((currency, value) {
          currencyRates[currency] = value.toDouble();
        });
        rates[date] = currencyRates;
      });
    }

    return MetalPriceResponse(
      success: json['success'],
      base: json['base'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      rates: rates,
    );
  }
}
