# Drip Emporium Mobile App

A Flutter mobile application for Drip Emporium.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Configuration

This project uses a configuration file (`lib/config/app_config.dart`) to manage sensitive API keys and other environment-specific variables. This file is intentionally ignored by Git (`.gitignore`) to prevent secrets from being committed to version control.

**To set up your local configuration:**

1.  **Create the configuration file:**
    Create a file named `app_config.dart` inside the `lib/config/` directory.

2.  **Add content to `app_config.dart`:**
    Copy the following content into `lib/config/app_config.dart`. **Replace the placeholder values with your actual API keys.**

    ```dart
    class AppConfig {
      static const String paystackLiveSecretKey = "sk_live_YOUR_PAYSTACK_LIVE_SECRET_KEY";
      static const String paystackPublicKey = "pk_live_YOUR_PAYSTACK_PUBLIC_KEY";
      static const String paystackSecretKey = "sk_test_YOUR_PAYSTACK_SECRET_KEY"; // For server-side verification
    }
    ```

    *   `paystackLiveSecretKey`: Your live secret key for Paystack API calls from the client-side (e.g., for transaction initialization).
    *   `paystackPublicKey`: Your public key for Paystack SDK initialization.
    *   `paystackSecretKey`: Your secret key for server-side verification of transactions. **This should ideally only be used on your backend server, not directly in the mobile app.**

**Important Security Note:** Never commit your actual API keys or other sensitive information to version control. The `lib/config/app_config.dart` file is already configured to be ignored by Git.
