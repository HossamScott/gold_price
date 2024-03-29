import 'package:flutter/material.dart';
import 'package:gold_price/WebViewScreen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:gold_price/network/GoldAPIService.dart';
import 'package:gold_price/PriceCalculator.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  List<int> numbers = [18, 21, 22, 24]; // List of numbers to display
  TextEditingController weightController = TextEditingController();
  List<String> karatValues = [
    '10k',
    '12k',
    '14k',
    '16k',
    '18k',
    '21.6k',
    '21k',
    '22k',
    '23k',
    '24k',
    '6k',
    '8k',
    '9k'
  ];
  Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'EGP': 'LE',
    'IQD': 'IQD',
    'LBP': 'LBP',
    'SAR': 'SAR',
    'MAD': 'MAD',
    'TND': 'TND',
    'KWD': 'KWD',
    'DZD': 'DZD',
    'BHD': 'BHD',
    'QAR': 'QAR',
    'AED': 'AED',
    'OMR': 'OMR'
  };
  Map<String, String> metalTypeToAPIValue = {
    'Gold': 'XAU',
    'Silver': 'XAG'
    // 'Platinum': 'XPT',
    // 'Palladium': 'XPD',
  };
  int? selectedNumber = 18;
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
  // ca-app-pub-1118657996955561/7146624551

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
    goldPriceFuture =
        GoldAPIService.fetchGoldPrice(selectedCurrency ?? 'USD').then((data) {
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
    print("testtest $data");
    double weight =
        double.tryParse(weightController.text) ?? 0.0; // Parse the weight input

    if (selectedNumber != null && weight > 0.0) {
      // Check if weight is more than 0
      double originalPricePerGram =
          PriceCalculator.getPricePerGram(selectedNumber.toString(), data);
      double pricePerGram = originalPricePerGram *
          5; // Multiply the price by 5 (or your specific logic)
      double total = weight * pricePerGram;

      String currencySymbol = currencySymbols[selectedCurrency] ?? '';
      setState(() {
        totalValue =
            '${total.toStringAsFixed(3)} $currencySymbol'; // Set the calculated total
      });
    } else {
      setState(() {
        totalValue =
            '0 ${currencySymbols[selectedCurrency] ?? ''}'; // Reset to 0 if weight is not valid
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
                              icon: Icon(Icons.policy,
                                  color: Color(0xFFE0BF73)),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => WebViewScreen(url: 'https://tichcheap.com/%D8%B3%D9%8A%D8%A7%D8%B3%D8%A9-%D8%A7%D9%84%D8%AE%D8%B5%D9%88%D8%B5%D9%8A%D8%A9/')),
                                );
                              },
                            ),
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
                                      buildPriceInfo('18', data['data']['18k'],
                                          currencySymbol),
                                      buildPriceInfo('21', data['data']['21k'],
                                          currencySymbol),
                                      buildPriceInfo('22', data['data']['22k'],
                                          currencySymbol),
                                      buildPriceInfo('24', data['data']['24k'],
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
                      SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.only(
                            left: 10.0, right: 10.0, top: 5.0, bottom: 10.0),
                        // Reduced top padding
                        child: Text(
                          'احسب قيمه الذهب',
                          style: TextStyle(
                            color: Color(0xFFF6E9C9), // Text color
                            fontWeight: FontWeight.bold, // Bold font
                            fontSize:
                                25, // Optional: Adjust font size as needed
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
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFFFFCE7),
                                          Color(0xFFDAA53F)
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
                                    child: TextButton(
                                      onPressed: () {
                                        if (goldPriceFuture != null) {
                                          goldPriceFuture!.then((data) {
                                            FocusManager.instance.primaryFocus?.unfocus();
                                            calculateTotal(data);
                                          });
                                        }
                                      },
                                      child: Text('احسب',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20)),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          border: Border.all(
                                              color: Color(0xFFDAA53F),
                                              width: 1), // Gold border
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        child: DropdownButton<int>(
                                          value: selectedNumber,
                                          isExpanded: true,
                                          underline: SizedBox(),
                                          onChanged: (newValue) {
                                            if (newValue != null) {
                                              setState(() {
                                                selectedNumber = newValue;
                                                if (goldPriceFuture != null) {
                                                  goldPriceFuture!.then((data) {
                                                    calculateTotal(data);
                                                  });
                                                }
                                              });
                                            }
                                          },
                                          items: numbers.map((int number) {
                                            return DropdownMenuItem<int>(
                                              value: number,
                                              child: Center(
                                                child: Text(
                                                  number.toString(),
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          // White background color
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          // Curve radius
                                          border: Border.all(
                                              color: Color(0xFFDAA53F),
                                              width: 1), // Gold border
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        child: TextField(
                                          controller: weightController,
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          // Restrict keyboard to number input
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                                RegExp(r'^\d+\.?\d*')),
                                          ],
                                          // onChanged: (value) {
                                          //   if (goldPriceFuture != null) {
                                          //     goldPriceFuture!.then((data) {
                                          //       calculateTotal(data);
                                          //     });
                                          //   }
                                          // },
                                          decoration: InputDecoration(
                                            hintText: '0',
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    vertical: 10.0),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Container(
                              height: 1, // Height of the line
                              color: Color(0xFFDAA53F), // Gold color for the line
                              width: double.infinity, // Full width line
                            ),
                            SizedBox(height: 10),
                            // Spacing between the row and the output value
                            // Display the output value
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Dynamic value on the left
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    '$totalValue',
                                    textAlign: TextAlign.left,
                                    // Align text to start from the left
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFDAA53F), // Gold color
                                      fontSize: 25,
                                    ),
                                  ),
                                ),
                                // Static text "Output Value:" on the right
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'قيمه الذهب',
                                    textAlign: TextAlign.right,
                                    // Align text to start from the right
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      fontSize: 25,
                                    ),
                                  ),
                                ),
                              ],
                            )
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

  Widget buildPriceInfo(
      String karatLabel, dynamic originalPrice, String currencySymbol) {
    // Rename the local variable to avoid conflict with the parameter
    double multipliedPrice = (originalPrice != null) ? originalPrice * 5 : 0.0;
    String priceString = (originalPrice != null)
        ? '$currencySymbol  ${multipliedPrice.toStringAsFixed(2)}'
        : 'N/A';

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
              padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
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
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    children: <TextSpan>[
                      TextSpan(text: '$karatLabel'),
                      TextSpan(text: ' سعر جرام الدهب عيار'), // Space included before the text
                    ],
                  ),
                ),
              )
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
