enum PaymentMethods {
  card,
  account,
  cash,
  payPal,
  googlePay,
  applePay,
  bankTransfer;

  static PaymentMethods? fromString(String value) {
    switch (value) {
      case 'Card':
        return PaymentMethods.card;
      case 'Account':
        return PaymentMethods.account;
      case 'Cash':
        return PaymentMethods.cash;
      case 'PayPal':
        return PaymentMethods.payPal;
      case 'Google Pay':
        return PaymentMethods.googlePay;
      case 'Apple Pay':
        return PaymentMethods.applePay;
      case 'Bank Transfer':
        return PaymentMethods.bankTransfer;
      default:
        return null;
    }
  }

  @override
  String toString() {
    return name[0].toUpperCase() + name.substring(1);
  }
}
