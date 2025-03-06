enum PaymentMethods {
  payPal,
  applePay,
  transfer,
  cash;

  static PaymentMethods? fromString(String value) {
    switch (value) {
      case 'PayPal':
        return PaymentMethods.payPal;
      case 'ApplePay':
        return PaymentMethods.applePay;
      case 'Transfer':
        return PaymentMethods.transfer;
      case 'Cash':
        return PaymentMethods.cash;
      default:
        return null;
    }
  }

  @override
  String toString() {
    return "${name[0].toUpperCase()}${name.substring(1)}";
  }

}
