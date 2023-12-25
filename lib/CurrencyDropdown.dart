import 'package:flutter/material.dart';

class CurrencyDropdown extends StatelessWidget {
  final String? selectedCurrency; // Corrected name
  final Map<String, String> currencySymbols;
  final ValueChanged<String?> onCurrencyChanged;

  const CurrencyDropdown({
    Key? key,
    required this.selectedCurrency, // Corrected name
    required this.currencySymbols,
    required this.onCurrencyChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          value: selectedCurrency, // Corrected to use the existing variable
          isExpanded: true,
          underline: Container(),
          icon: Icon(Icons.arrow_drop_down, color: Colors.black),
          onChanged: onCurrencyChanged, // Corrected to use the existing variable
          items: currencySymbols.keys.map((String key) { // Directly using the currencySymbols Map
            return DropdownMenuItem<String>(
              value: key,
              child: Text(
                key,  // Display the currency code (key) from currencySymbols
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
