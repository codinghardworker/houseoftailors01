# Stripe Integration Guide

This Flutter app includes a complete Stripe integration for processing payments with email, shipping address, and card payment functionality.

## Features

- ✅ Complete checkout flow with email and shipping address collection
- ✅ Secure card payment processing with Stripe
- ✅ Test mode and production mode support
- ✅ Comprehensive error handling
- ✅ Order history storage
- ✅ Payment validation
- ✅ Retry payment functionality
- ✅ Production-ready security

## Setup Instructions

### 1. Stripe Account Setup

1. Create a Stripe account at https://stripe.com
2. Get your API keys from the Stripe Dashboard
3. Replace the keys in `lib/config/stripe_config.dart`:

```dart
// Test mode keys
static const String testPublishableKey = 'pk_test_YOUR_TEST_KEY_HERE';

// Production keys  
static const String prodPublishableKey = 'pk_live_YOUR_LIVE_KEY_HERE';
```

### 2. Test Mode

The app is configured to run in test mode by default (controlled by `kDebugMode`). In test mode:

- Uses test Stripe keys
- Accepts test card numbers
- No real money is processed

#### Test Card Numbers

Use these test card numbers for testing:

- **Visa**: `4242 4242 4242 4242`
- **Visa (debit)**: `4000 0566 5566 5556`
- **Mastercard**: `5555 5555 5555 4444`
- **American Express**: `3782 822463 10005`
- **Declined card**: `4000 0000 0000 0002`

Use any future expiry date and any 3-digit CVC.

### 3. Production Mode

For production deployment:

1. Update the publishable key in `stripe_config.dart`
2. Set up a backend server to handle payment intents (see Backend Setup below)
3. Update the `_getSecretKey()` method in `stripe_service.dart` to call your backend

## File Structure

```
lib/
├── config/
│   └── stripe_config.dart          # Stripe configuration
├── services/
│   ├── stripe_service.dart         # Stripe API service
│   └── payment_service.dart        # Payment processing logic
├── screens/
│   ├── basket_screen.dart          # Shopping cart with checkout button
│   └── checkout_screen.dart        # Payment form
└── main.dart                       # Stripe initialization

test/
└── stripe_test.dart                # Unit tests
```

## How to Use

### 1. Add Items to Cart

Users can add items to their cart through the tailor flow. The cart is managed by `CartProvider`.

### 2. Checkout Flow

1. Navigate to basket screen
2. Pull up the bottom drawer
3. Click "Go to checkout"
4. Fill in contact information
5. Fill in shipping address
6. Enter card details
7. Click "Pay" button

### 3. Payment Processing

The payment flow:

1. Validates all form inputs
2. Creates a payment intent with Stripe
3. Confirms the payment with card details
4. Saves order to local storage
5. Clears the cart
6. Shows success message

## Error Handling

The integration includes comprehensive error handling for:

- Invalid card numbers
- Expired cards
- Insufficient funds
- Network errors
- Validation errors
- Stripe API errors

## Security Features

- ✅ PCI-compliant card handling (Stripe handles sensitive data)
- ✅ Client-side validation
- ✅ Secure API communication
- ✅ No sensitive data stored locally
- ✅ Test/production environment separation

## Backend Setup (Production)

For production, you'll need a backend server to:

1. Create payment intents
2. Handle webhooks
3. Manage customer data
4. Process refunds

### Sample Backend Endpoint

```javascript
// Node.js/Express example
app.post('/create-payment-intent', async (req, res) => {
  const { amount, currency, customer_email } = req.body;

  const paymentIntent = await stripe.paymentIntents.create({
    amount: amount,
    currency: currency,
    receipt_email: customer_email,
    automatic_payment_methods: {
      enabled: true,
    },
  });

  res.send({
    client_secret: paymentIntent.client_secret,
  });
});
```

## Testing

Run the tests:

```bash
flutter test test/stripe_test.dart
```

## Important Notes

1. **Secret Keys**: Never store secret keys in client-side code in production
2. **Backend Required**: For production, implement a backend to handle payment intents
3. **Webhooks**: Set up Stripe webhooks to handle payment confirmations
4. **Validation**: Always validate payments server-side
5. **PCI Compliance**: Stripe handles PCI compliance for card data

## Troubleshooting

### Common Issues

1. **"Invalid API key"**: Check your Stripe keys in `stripe_config.dart`
2. **"Your card was declined"**: Use a valid test card number
3. **"Network error"**: Check internet connection
4. **"Invalid amount"**: Ensure cart has items with valid prices

### Debug Mode

The app includes debug logging. Check the console for:
- Payment intent creation
- API responses
- Error messages
- Cart state changes

## Support

For Stripe-specific issues:
- [Stripe Documentation](https://stripe.com/docs)
- [Stripe Flutter SDK](https://pub.dev/packages/flutter_stripe)
- [Stripe Support](https://support.stripe.com)

## License

This integration is part of the House of Tailors app. Use according to your app's license terms.