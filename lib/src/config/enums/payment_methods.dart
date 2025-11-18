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
    switch (this) {
      case PaymentMethods.card:
        return 'Card';
      case PaymentMethods.account:
        return 'Account';
      case PaymentMethods.cash:
        return 'Cash';
      case PaymentMethods.payPal:
        return 'PayPal';
      case PaymentMethods.googlePay:
        return 'Google Pay';
      case PaymentMethods.applePay:
        return 'Apple Pay';
      case PaymentMethods.bankTransfer:
        return 'Bank Transfer';
    }
  }
}
