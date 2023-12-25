import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gold_price/network/GoldAPIService.dart';
import 'package:gold_price/network/MetalPriceResponse.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class InsightsPage extends StatefulWidget {
  @override
  _InsightsPageState createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {

  late BannerAd _topBannerAd;
  late BannerAd _bottomBannerAd;
  bool _isTopBannerAdLoaded = false;
  bool _isBottomBannerAdLoaded = false;

  List<FlSpot>? _chartData;
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
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // replace with your ad unit id for the top banner
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
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // replace with your ad unit id for the bottom banner
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
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _selectedStartDate : _selectedEndDate,
      firstDate: DateTime(2015, 1),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _selectedStartDate = picked;
        } else {
          _selectedEndDate = picked;
        }
      });
    }
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
                    Opacity(opacity: 0, child: IconButton(icon: Icon(Icons.arrow_back), onPressed: null)),
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
              Center(child: Text('Please Select Range', style: TextStyle(color: Color(0xFFE0BF73)))),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _timeRangeButtons.map((button) {
                    return ElevatedButton(
                      onPressed: () => _fetchAndPlotData(DateTime.now().subtract(button.duration), DateTime.now()),
                      child: Text(button.title),
                      style: ElevatedButton.styleFrom(primary: Color(0xFFE0BF73)),
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
                        startDate: _selectedStartDate,  // Pass the start date here
                        endDate: _selectedEndDate      // Pass the end date here
                    ),
                )
              else
                Center(child: Text('No data to display', style: TextStyle(color: Colors.white))),

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

    String formattedStartDate = "${_selectedStartDate.toIso8601String().split('T')[0]}";
    String formattedEndDate = "${_selectedEndDate.toIso8601String().split('T')[0]}";

    try {
      MetalPriceResponse response = await GoldAPIService.fetchMetalPriceTimeframe(formattedStartDate, formattedEndDate, "XAU","USD");

      List<FlSpot> chartData = [];
      response.rates.forEach((date, rateMap) {
        double xValue = DateTime.parse(date).millisecondsSinceEpoch.toDouble();
        double yValue = rateMap['USD']?.toDouble() ?? 0;
        chartData.add(FlSpot(xValue, yValue/ 31.1034768));
      });

      setState(() {
        _chartData = chartData;
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
  final List<FlSpot> data;
  final Map<String, dynamic> rates;
  final DateTime startDate;
  final DateTime endDate;

  MetalPriceChart({required this.data, required this.rates, required this.startDate, required this.endDate});

  @override
  Widget build(BuildContext context) {
    int totalDays = endDate.difference(startDate).inDays;
    int labelFrequency = 1;  // Show label for every day by default.

    // Adjust label frequency based on the date range
    if (totalDays > 1 && totalDays <= 7) {
      labelFrequency = 1;  // For 7 days or fewer, show every day
    } else if (totalDays > 7 && totalDays <= 30) {
      labelFrequency = 7;  // For more than 7 days, show weekly
    } else if (totalDays > 30) {
      labelFrequency = 30; // For more than 30 days, show monthly
    }

    // Prepare to track the last labeled day to avoid duplication
    int lastLabeledDay = -1;

    return Container(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: SideTitles(
              showTitles: true,
              rotateAngle: 45,
              reservedSize: 30,
              getTextStyles: (context, value) => const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              getTitles: (value) {
                DateTime date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                int dayOfYear = int.parse(DateFormat("D").format(date));

                // Check if the day should be labeled and hasn't been labeled yet
                if ((dayOfYear % labelFrequency == 0) && (dayOfYear != lastLabeledDay)) {
                  lastLabeledDay = dayOfYear;
                  return DateFormat("dd/MM").format(date); // Adjust format as needed
                }
                return ''; // Don't show a label for this date.
              },
              margin: 8,
            ),
            leftTitles: SideTitles(
              showTitles: false,
              getTextStyles: (context, value) => const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              getTitles: (value) {
                // Modify this as needed for your dataset
                return '${value.toInt()}';
              },
              margin: 12,
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: data,
              isCurved: true,
              colors: [Color(0xFFE0BF73)],
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}

