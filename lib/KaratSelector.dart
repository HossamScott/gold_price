import 'package:flutter/material.dart';

class KaratSelector extends StatelessWidget {
  final int? selectedNumber;
  final List<int> numbers;
  final ValueChanged<int> onKaratChanged;  // This is the method you should call

  const KaratSelector({
    Key? key,
    required this.selectedNumber,
    required this.numbers,
    required this.onKaratChanged,  // Ensure this is passed in correctly
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: EdgeInsets.all(0.0),
      decoration: BoxDecoration(
        color: Color(0xFFF6E9C9),
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: numbers.length,
        itemBuilder: (context, index) {
          bool isSelected = selectedNumber == numbers[index];
          return GestureDetector(
            onTap: () {
              onKaratChanged(numbers[index]);  // Call the correct method here
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
                  color: isSelected ? Colors.black : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
