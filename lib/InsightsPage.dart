import 'package:flutter/material.dart';
import 'package:gold_price/network/GoldAPIService.dart';
import 'package:gold_price/network/MetalPriceResponse.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
class InsightsPage extends StatefulWidget {
  @override
  _InsightsPageState createState() => _InsightsPageState();
}

class PriceData {
  PriceData(this.date, this.value);
  final String date;
  final double value;
}

class _InsightsPageState extends State<InsightsPage> {
  late BannerAd _topBannerAd;
  late BannerAd _bottomBannerAd;
  bool _isTopBannerAdLoaded = false;
  bool _isBottomBannerAdLoaded = false;
  List<PriceData>? _chartData;
  DateTime _selectedStartDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _selectedEndDate = DateTime.now();
  bool _isLoading = false;
  Map<String, dynamic> _ratesData = {}; // Placeholder for your rates data
  // Define the time range buttons
  List<TimeRangeButton> _timeRangeButtons = [
    TimeRangeButton(title: "1 Month", duration: Duration(days: 30)),
    TimeRangeButton(title: "3 Months", duration: Duration(days: 90)),
    TimeRangeButton(title: "6 Months", duration: Duration(days: 180)),
  ];

  @override
  void initState() {
    super.initState();
    _topBannerAd = createTopBannerAd()..load();
    _bottomBannerAd = createBottomBannerAd()..load();
  }

  BannerAd createTopBannerAd() {
    return BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      // replace with your ad unit id for the top banner
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isTopBannerAdLoaded = true),
        onAdFailedToLoad: (ad, error) {
          print('Top Banner failed to load: $error');
          ad.dispose();
        },
      ),
    );
  }

  BannerAd createBottomBannerAd() {
    return BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      // replace with your ad unit id for the bottom banner
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBottomBannerAdLoaded = true),
        onAdFailedToLoad: (ad, error) {
          print('Bottom Banner failed to load: $error');
          ad.dispose();
        },
      ),
    );
  }

  @override
  void dispose() {
    _topBannerAd.dispose();
    _bottomBannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF191919),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Color(0xFFE0BF73)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Historical Data',
                      style: TextStyle(
                        color: Color(0xFFE0BF73),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Opacity(
                        opacity: 0,
                        child: IconButton(
                            icon: Icon(Icons.arrow_back), onPressed: null)),
                  ],
                ),
              ),
              if (_isTopBannerAdLoaded)
                Container(
                  child: AdWidget(ad: _topBannerAd!),
                  width: _topBannerAd!.size.width.toDouble(),
                  height: _topBannerAd!.size.height.toDouble(),
                  alignment: Alignment.center,
                ),
              SizedBox(height: 10),
              Center(
                  child: Text('Please Select Range',
                      style: TextStyle(color: Color(0xFFE0BF73)))),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _timeRangeButtons.map((button) {
                    return ElevatedButton(
                      onPressed: () => _fetchAndPlotData(
                          DateTime.now().subtract(button.duration),
                          DateTime.now()),
                      child: Text(button.title),
                      style:
                          ElevatedButton.styleFrom(primary: Color(0xFFE0BF73)),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 10),
              if (_isLoading)
                // Show shimmer effect while loading
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 300,
                      color: Colors.white,
                    ),
                  ),
                )
              else if (_chartData != null && _chartData!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: MetalPriceChart(
                      data: _chartData!,
                      rates: _ratesData,
                      startDate: _selectedStartDate,
                      // Pass the start date here
                      endDate: _selectedEndDate // Pass the end date here
                      ),
                )
              else
                Center(
                    child: Text('No data to display',
                        style: TextStyle(color: Colors.white))),
              SizedBox(height: 30),
              if (_isBottomBannerAdLoaded)
                Container(
                  child: AdWidget(ad: _bottomBannerAd),
                  width: _bottomBannerAd.size.width.toDouble(),
                  height: _bottomBannerAd.size.height.toDouble(),
                  alignment: Alignment.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _fetchAndPlotData(DateTime start, DateTime end) async {
    setState(() {
      _isLoading = true;
      _selectedStartDate = start;
      _selectedEndDate = end;
    });

    String formattedStartDate =
        "${_selectedStartDate.toIso8601String().split('T')[0]}";
    String formattedEndDate =
        "${_selectedEndDate.toIso8601String().split('T')[0]}";

    try {
      MetalPriceResponse response =
      await GoldAPIService.fetchMetalPriceTimeframe(
          formattedStartDate, formattedEndDate, "XAU", "USD");

      List<PriceData> chartData = response.rates.entries.map((entry) {
        String date = entry.key; // Assuming the date is a string.
        double value = entry.value['USD']?.toDouble() ?? 0; // Convert to a double.
        return PriceData(date, value / 31.1034768); // Create a PriceData object.
      }).toList();

      setState(() {
        _chartData = chartData; // Now this is a List<PriceData>
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class TimeRangeButton {
  final String title;
  final Duration duration;

  TimeRangeButton({required this.title, required this.duration});
}

class MetalPriceChart extends StatelessWidget {
  final List<PriceData> data;
  final Map<String, dynamic> rates;
  final DateTime startDate;
  final DateTime endDate;

  MetalPriceChart(
      {required this.data,
      required this.rates,
      required this.startDate,
      required this.endDate});

  int calculateLabelInterval(double screenWidth, int dataLength) {
    // Define base intervals for different screen widths
    int baseInterval = screenWidth > 600 ? 1 : 4;

    // Adjust the interval based on the number of data points
    int adjustedInterval = (dataLength / 10).ceil(); // Adjust this as needed

    // Choose the greater interval to avoid label clutter on small screens
    return max(baseInterval, adjustedInterval);
  }

  @override
  Widget build(BuildContext context) {
    int totalDays = endDate.difference(startDate).inDays;
    int labelFrequency = 1; // Show label for every day by default.
    // Get the screen width
    double screenWidth = MediaQuery.of(context).size.width;

    // Calculate the label interval
    int labelInterval = calculateLabelInterval(screenWidth, data.length);

    // Adjust label frequency based on the date range
    if (totalDays > 1 && totalDays <= 7) {
      labelFrequency = 1; // For 7 days or fewer, show every day
    } else if (totalDays > 7 && totalDays <= 30) {
      labelFrequency = 7; // For more than 7 days, show weekly
    } else if (totalDays > 30) {
      labelFrequency = 30; // For more than 30 days, show monthly
    }

    // Prepare to track the last labeled day to avoid duplication
    int lastLabeledDay = -1;

    return Container(
      height: 300,
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(
          labelRotation: 45,
          labelStyle: TextStyle(color: Colors.white),
          majorGridLines: MajorGridLines(width: 0),
        ),
        primaryYAxis: NumericAxis(
          interval: 2,
          numberFormat: NumberFormat("0.00"),
          labelStyle: TextStyle(color: Colors.white),
          majorGridLines: MajorGridLines(width: 0),
        ),
        legend: Legend(isVisible: false),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <LineSeries<PriceData, String>>[
          LineSeries<PriceData, String>(
            dataSource: data,
            xValueMapper: (PriceData sales, _) => sales.date,
            yValueMapper: (PriceData sales, _) => sales.value,
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              textStyle: TextStyle(color: Colors.white),
              // Use the builder to conditionally show labels.
              builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                int totalPoints = this.data.length; // Get the total number of data points from the series data
                int labelInterval = determineLabelInterval(totalPoints);  // Now passing totalPoints

                if (pointIndex % labelInterval == 0) {  // Show label at the interval
                  return Container(
                    child: Text(
                      '${(data as PriceData).value.toStringAsFixed(2)}', // 2 decimal places
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  );
                }
                return Container(); // Empty container for other points
              },
            ),
          )
        ],
      ),
    );
  }
}
int determineLabelInterval(int totalPoints) {
  int xLabelCount = 10; // Example: if you want 10 labels on the X-axis
  return (totalPoints / xLabelCount).floor(); // Calculate interval
}
