class CalculationUtils {
  static double calculateTotalPrice(double pricePerHour, DateTime pickup, DateTime drop) {
    Duration duration = drop.difference(pickup);
    double hours = duration.inMinutes / 60.0;
    return hours * pricePerHour;
  }

  static Map<String, double> calculateCancellationRefund(double totalAmount, DateTime pickupTime) {
    DateTime now = DateTime.now();
    Duration difference = pickupTime.difference(now);

    if (difference.inHours >= 24) {
      return {'refund': totalAmount, 'penalty': 0.0};
    } else {
      double penalty = totalAmount * 0.10;
      double refund = totalAmount - penalty;
      return {'refund': refund, 'penalty': penalty};
    }
  }

  static double calculateDelayCharges(double pricePerHour, DateTime dropTime, DateTime actualReturnTime) {
    Duration delay = actualReturnTime.difference(dropTime);
    if (delay.inHours <= 2) {
      return 0.0;
    } else {
      // Delay fine = 0.5 * Hourly rate * Hours Delayed
      double hours = delay.inMinutes / 60.0;
      return 0.5 * pricePerHour * hours;
    }
  }
}
