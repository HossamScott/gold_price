import 'package:flutter/material.dart';

class PriceInfoCard extends StatelessWidget {
  final String karatLabel;
  final dynamic price;
  final String currencySymbol;

  const PriceInfoCard({
    Key? key,
    required this.karatLabel,
    required this.price,
    required this.currencySymbol,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String priceString = (price != null) ? '$currencySymbol${price.toStringAsFixed(2)}' : 'N/A';
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(vertical: 5),
      padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Your price info widgets here
          ],
        ),
      ),
    );
  }
}
