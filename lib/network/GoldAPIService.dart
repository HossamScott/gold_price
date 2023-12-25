import 'package:gold_price/network/MetalPriceResponse.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GoldAPIService {
  static const String _goldAccessToken = 'goldapi-2gnfkbgrlqglw4dl-io'; // Your Gold API access token
  static const String _metalPriceApiKey = 'bc6bfc351b85633a648f56a94a42c39e'; // Your Metal Price API key

  static Future<Map<String, dynamic>> fetchGoldPrice(String currency) async {
    String caratPriceApiUrl = 'https://api.metalpriceapi.com/v1/carat?api_key=$_metalPriceApiKey&base=$currency';

    try {
      final response = await http.get(Uri.parse(caratPriceApiUrl));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load gold carat price data');
      }
    } catch (e) {
      throw Exception('Error occurred: $e');
    }
  }

  static Future<MetalPriceResponse> fetchMetalPriceTimeframe(String startDate, String endDate, String base, String currencies) async {
    // Updated API URL with the new parameters
    String metalPriceApiUrl = 'https://api.metalpriceapi.com/v1/timeframe?api_key=$_metalPriceApiKey&base=$base&currencies=$currencies&start_date=$startDate&end_date=$endDate';
    print("API Request: $metalPriceApiUrl");

    try {
      final response = await http.get(Uri.parse(metalPriceApiUrl));

      if (response.statusCode == 200) {
        print("API Response: ${response.body}");
        return MetalPriceResponse.fromJson(json.decode(response.body));
      } else {
        print("Failed to load metal price data");
        throw Exception('Failed to load metal price data');
      }
    } catch (e) {
      print("Error occurred: $e");
      throw Exception('Error occurred: $e');
    }
  }
}
