import 'package:flutter/material.dart';
import 'package:gold_price/InsightsPage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:gold_price/network/GoldAPIService.dart';
import 'package:gold_price/PriceCalculator.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Define your state variables here
  String? selectedCurrency = 'USD'; // For the Currency dropdown
  String? selectedType = 'Gold'; // For the Type dropdown
  String lastUpdateTime = ''; // Variable to store last update time
  String totalValue = '0'; // Variable to store the total calculated price
  Future<Map<String, dynamic>>? goldPriceFuture;
  int? selectedNumber;
  List<int> numbers = [18, 21, 22, 24]; // List of numbers to display
  TextEditingController weightController = TextEditingController();
  List<String> karatValues = ['10k', '12k', '14k', '16k', '18k', '21.6k', '21k', '22k', '23k', '24k', '6k', '8k', '9k'];
  Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'EGP': 'E£',
    'IQD': 'IQD', 
    'LBP': 'LBP', 
    'SAR': '﷼',
    'MAD': 'MAD', 
    'TND': 'TND', 
    'KWD': 'د.ك',
    'DZD': 'DZD', 
    'BHD': 'ب.د',
    'QAR': 'ر.ق',
    'AED': 'د.إ',
    'OMR': 'ر.ع.'
  };

  Map<String, String> metalTypeToAPIValue = {
    'Gold': 'XAU',
    'Silver': 'XAG'
    // 'Platinum': 'XPT',
    // 'Palladium': 'XPD',
  };

  late BannerAd _topBannerAd;
  late BannerAd _bottomBannerAd;
  bool _isTopBannerAdLoaded = false;
  bool _isBottomBannerAdLoaded = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  @override
  void initState() {
    super.initState();
    selectedNumber = 18;
    _topBannerAd = createTopBannerAd()..load();
    _bottomBannerAd = createBottomBannerAd()..load();
    _loadInterstitialAd();
    fetchDataAndResetCalculator();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712',
      // Replace with your ad unit ID
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          this._interstitialAd = ad;
          _isInterstitialAdReady = true;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              // Dispose the current ad and load a new one
              ad.dispose();
              _loadInterstitialAd();
              _isInterstitialAdReady = false;

              // Navigate to InsightsPage when ad is dismissed
              Navigator.pushNamed(context, '/insights');
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              // Handle the error and continue to the InsightsPage
              print('Ad failed to show: $err');
              ad.dispose();
              _loadInterstitialAd();
              _isInterstitialAdReady = false;

              // Continue to InsightsPage
              Navigator.pushNamed(context, '/insights');
            },
          );
        },
        onAdFailedToLoad: (err) {
          print('Failed to load an interstitial ad: ${err.message}');
          _isInterstitialAdReady = false;
        },
      ),
    );
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
    _interstitialAd?.dispose();
    super.dispose();
  }

  void fetchDataAndResetCalculator() {
    goldPriceFuture = GoldAPIService.fetchGoldPrice(
            selectedCurrency ?? 'USD')
        .then((data) {
      if (mounted) {
        setState(() {
          lastUpdateTime = formatTimestamp(data['timestamp'] ?? 0);
          weightController.clear();
          totalValue = '0 ${currencySymbols[selectedCurrency]}';
          calculateTotal(data);
        });
      }
      return data; // Return the data for FutureBuilder to use
    });
  }

  String formatTimestamp(int timestamp) {
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  void calculateTotal(Map<String, dynamic> data) {
    if (selectedNumber != null && weightController.text.isNotEmpty) {
      double weight = double.tryParse(weightController.text) ?? 0.0;

      double originalPricePerGram  = PriceCalculator.getPricePerGram(selectedNumber.toString(), data);
      double pricePerGram = originalPricePerGram * 5; // Multiply the price by 5
      double total = weight * pricePerGram;

      String currencySymbol = currencySymbols[selectedCurrency] ?? '';
      setState(() {
        totalValue = '${total.toStringAsFixed(2)} $currencySymbol';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF191919),
      body: SafeArea(
        child: Column(
          children: [
            if (_isTopBannerAdLoaded)
              Container(
                child: AdWidget(ad: _topBannerAd!),
                width: _topBannerAd!.size.width.toDouble(),
                height: _topBannerAd!.size.height.toDouble(),
                alignment: Alignment.center,
              ),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(
                            left: 10.0, right: 10.0, top: 5.0, bottom: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          // Align items to the center of the Row
                          mainAxisSize: MainAxisSize.max,
                          // Use the maximum space available
                          children: [
                            IconButton(
                              icon: Icon(Icons.insights,
                                  color: Color(0xFFE0BF73)),
                              onPressed: () {
                                if (_isInterstitialAdReady) {
                                  _interstitialAd?.show();
                                } else {
                                  _loadInterstitialAd();
                                  Navigator.pushNamed(context, '/insights');
                                }
                              },
                            ),
                            Expanded(
                              // Use Expanded to push the text to the center
                              child: Text(
                                'Gold Price',
                                textAlign: TextAlign.center,
                                // Align the text to the center of the Expanded widget
                                style: TextStyle(
                                  color: Color(0xFFE0BF73),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            Opacity(
                              opacity: 0, // Invisible icon to balance the row
                              child: IconButton(
                                icon:
                                    Icon(Icons.menu, color: Color(0xFFE0BF73)),
                                onPressed: null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            left: 10.0, right: 10.0, top: 5.0, bottom: 10.0),
                        // Reduced top padding
                        child: Text(
                          'اخر تحديث $lastUpdateTime',
                          // Replace 'xxx' with the actual update time
                          style: TextStyle(
                            color: Color(0xFFF6E9C9), // Text color
                            fontWeight: FontWeight.bold, // Bold font
                            fontSize:
                                16, // Optional: Adjust font size as needed
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Color(0xFFF6E9C9), // Main background color
                          borderRadius:
                              BorderRadius.circular(15.0), // Curve radius
                        ),
                        child: Column(
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: dropdownContainer(selectedCurrency,
                                      (newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          selectedCurrency = newValue;
                                          fetchDataAndResetCalculator(); // Refetch data and reset calculator
                                        });
                                      }
                                  }, currencySymbols.keys.toList()),
                                ),
                                // SizedBox(width: 5),
                                // // Space between the dropdowns
                                // Expanded(
                                //   child: dropdownContainer(selectedType,
                                //       (newValue) {
                                //     setState(() {
                                //       selectedType = newValue;
                                //       fetchDataAndResetCalculator(); // Refetch data and reset calculator
                                //     });
                                //   }, <String>['Gold', 'Silver']),
                                // ),
                              ],
                            ),
                            SizedBox(height: 10),
                            // Space between dropdowns and the price line
                            FutureBuilder<Map<String, dynamic>>(
                              future: goldPriceFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  // Show shimmer effect while loading
                                  return Container(
                                    // Added a container to give a defined height
                                    height: 240,
                                    // Adjust the height as needed for your UI
                                    child: ListView.builder(
                                      itemCount: 4,
                                      // Assuming 4 items for 18k, 21k, 22k, and 24k
                                      itemBuilder: (context, index) {
                                        return Shimmer.fromColors(
                                          baseColor: Colors.grey[300]!,
                                          highlightColor: Colors.grey[100]!,
                                          child: Container(
                                            height: 50,
                                            margin: EdgeInsets.symmetric(
                                                vertical: 8, horizontal: 16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                } else if (snapshot.hasError) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text('Error: ${snapshot.error}'),
                                  );
                                } else if (snapshot.hasData) {
                                  Map<String, dynamic> data = snapshot.data!;
                                  String currencySymbol =
                                      currencySymbols[selectedCurrency] ?? '';
                                  return Column(
                                    children: <Widget>[
                                      buildPriceInfo(
                                          '18',
                                          data['data']['18k'],
                                          currencySymbol),
                                      buildPriceInfo(
                                          '21',
                                          data['data']['21k'],
                                          currencySymbol),
                                      buildPriceInfo(
                                          '22',
                                          data['data']['22k'],
                                          currencySymbol),
                                      buildPriceInfo(
                                          '24',
                                          data['data']['24k'],
                                          currencySymbol),
                                    ],
                                  );
                                } else {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text('No data available'),
                                  );
                                }
                              },
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            left: 10.0, right: 10.0, top: 5.0, bottom: 10.0),
                        // Reduced top padding
                        child: Text(
                          'حدد عيار الذهب',
                          // Replace 'xxx' with the actual update time
                          style: TextStyle(
                            color: Color(0xFFF6E9C9), // Text color
                            fontWeight: FontWeight.bold, // Bold font
                            fontSize:
                                25, // Optional: Adjust font size as needed
                          ),
                        ),
                      ),
                      Container(
                        height: 60, // Define a fixed height
                        padding: EdgeInsets.all(0.0),
                        decoration: BoxDecoration(
                          color: Color(0xFFF6E9C9), // Main background color
                          borderRadius:
                              BorderRadius.circular(15.0), // Curve radius
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: numbers.length,
                          itemBuilder: (context, index) {
                            bool isSelected = selectedNumber == numbers[index];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedNumber = numbers[index];
                                  if (goldPriceFuture != null) {
                                    goldPriceFuture!.then((data) {
                                      calculateTotal(data);
                                    });
                                  }
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 10),
                                padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                                decoration: isSelected
                                    ? BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFFFFCE7),
                                            Color(0xFFDAA53F)
                                          ], // Gold gradient
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                      )
                                    : null,
                                alignment: Alignment.center,
                                child: Text(
                                  numbers[index].toString(),
                                  style: TextStyle(
                                    color:
                                        isSelected ? Colors.black : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 10),
                      // Container for value and weight
                      Container(
                        padding: EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Color(0xFFF6E9C9), // Main background color
                          borderRadius:
                              BorderRadius.circular(15.0), // Curve radius
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: Text(
                                    'القيمة',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Container(width: 30.0),
                                // Placeholder for the icon
                                Expanded(
                                  child: Text(
                                    'الوزن/جم',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10), // Spacing
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [
                                        Color(0xFFDAA53F),
                                        Color(0xFFDAA53F)
                                      ], // Gold gradient
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ).createShader(bounds),
                                    child: Text(
                                      totalValue,
                                      // This will display the calculated total
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.symmetric(horizontal: 10),
                                  // Added margin
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(
                                        0xFFDAA53F), // Gold color for the background
                                  ),
                                  child: Icon(Icons.transform,
                                      color: Colors.white, size: 20.0),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: weightController,
                                    textAlign: TextAlign.center,
                                    onChanged: (value) {
                                      // Recalculate the total whenever the weight changes
                                      if (goldPriceFuture != null) {
                                        goldPriceFuture!.then((data) {
                                          calculateTotal(data);
                                        });
                                      }
                                    },
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Color(0xFFEBD5AF),
                                      // Background color for the input
                                      hintText: '0',
                                      contentPadding:
                                          EdgeInsets.symmetric(vertical: 10.0),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        borderSide: BorderSide
                                            .none, // Remove default border
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
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
    );
  }

  Widget buildPriceInfo(String karatLabel, dynamic originalPrice, String currencySymbol) {
    // Rename the local variable to avoid conflict with the parameter
    double multipliedPrice = (originalPrice != null) ? originalPrice * 5 : 0.0;
    String priceString =
    (originalPrice != null) ? '$currencySymbol${multipliedPrice.toStringAsFixed(2)}' : 'N/A';

    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(vertical: 5),
      padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
      decoration: BoxDecoration(
        color: Colors.white, // White background for the row
        borderRadius: BorderRadius.circular(10), // Curved corners for the row
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(30, 0, 30, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFFCE7), Color(0xFFDAA53F)],
                  // Gold gradient
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                priceString,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$karatLabelسعر جرام الدهب عيار ',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget dropdownContainer(String? selectedValue,
      ValueChanged<String?> onChanged, List<String> keys) {
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.0),
        decoration: BoxDecoration(
          color: Color(0xFFEBD5AF), // Background color for the dropdown
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        child: DropdownButton<String>(
          value: selectedValue,
          isExpanded: true,
          underline: Container(),
          icon: Icon(Icons.arrow_drop_down, color: Colors.black),
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
          items: keys.map((String key) {
            return DropdownMenuItem<String>(
              value: key,
              child: Text(
                key, // Display the currency code (key) from currencySymbols
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
