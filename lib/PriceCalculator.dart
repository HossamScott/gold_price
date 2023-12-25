class PriceCalculator {
  static double getPricePerGram(String karatLabel, Map<String, dynamic> data) {
    switch (karatLabel.trim()) {
      case '18':
        return data['data']['18k'];
      case '21':
        return data['data']['21k'];
      case '22':
        return data['data']['22k'];
      case '24':
        return data['data']['24k'];
      default:
        return 0.0;
    }
  }
}
