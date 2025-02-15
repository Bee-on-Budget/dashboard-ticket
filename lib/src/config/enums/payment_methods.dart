enum PaymentMethods {
  payPal,
  applePay,
  transfer,
  cash;

  static PaymentMethods? fromString(String value) {
    switch (value) {
      case 'payPal':
        return PaymentMethods.payPal;
      case 'applePay':
        return PaymentMethods.applePay;
      case 'transfer':
        return PaymentMethods.transfer;
      case 'cash':
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
