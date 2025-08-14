# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Drip Emporium is a Flutter e-commerce mobile application with the tagline "Define Your Look, Own Your Style." The app features product browsing, cart management, favorites, payment processing via Paystack, Firebase authentication, and WhatsApp integration for order communication.

## Development Commands

### Flutter Development
- **Run app**: `flutter run`
- **Build for production**: `flutter build apk --release` (Android) or `flutter build ios --release` (iOS)
- **Install dependencies**: `flutter pub get`
- **Upgrade dependencies**: `flutter pub upgrade`
- **Clean build**: `flutter clean`
- **Analyze code**: `flutter analyze`
- **Run tests**: `flutter test`

### Code Quality
- **Lint check**: Uses `package:flutter_lints/flutter.yaml` via `analysis_options.yaml`
- **Format code**: `dart format .`

## Architecture & Key Components

### State Management
- **Provider Pattern**: Uses `provider: ^6.1.5` package
- **Main Providers**:
  - `ProductsProvider`: Manages product data, search functionality, and API calls
  - `CartProvider`: Handles shopping cart state and operations
  - `FavoritesProvider`: Manages user favorites

### Data Layer
- **DataRepository** (`lib/services/data_repository.dart`): Central data access layer
  - Handles product fetching from external API (`https://shengmtaa.com/api/private/facebook_catalog`)
  - Implements SQLite caching with 24-hour cache duration
  - Manages Firebase Firestore operations for orders and user data
  - Provides offline-first approach with cache fallback

### Authentication & User Management
- **Firebase Authentication**: Email/password and Google Sign-In
- **User data**: Stored in Firestore `users` collection
- **Order tracking**: Firestore `orders` collection with admin and user views

### Payment System
- **Paystack Integration**: Uses `paystack_flutter_sdk: ^0.0.1-alpha.2`
- **PaymentService** (`lib/services/payment_service.dart`): Handles payment initialization and verification
- **Deep linking**: App Links integration for payment callbacks (`/payment-success`, `/payment-callback`)

### Database Structure
- **Local SQLite**: Products caching with schema versioning
- **Firestore Collections**:
  - `users`: User profile data
  - `orders`: Order tracking with status management

## Configuration Requirements

### Required Configuration File
Create `lib/config/app_config.dart` with:
```dart
class AppConfig {
  static const String paystackLiveSecretKey = "sk_live_YOUR_KEY";
  static const String paystackPublicKey = "pk_live_YOUR_KEY";
  static const String paystackSecretKey = "sk_test_YOUR_KEY";
}
```
**Note**: This file is gitignored. Use `lib/config/sample.app_config.dart` as template.

### Firebase Setup
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`
- macOS: `macos/Runner/GoogleService-Info.plist`

## Key Features Implementation

### Product Management
- **Product fetching**: External API integration with local SQLite caching
- **Search functionality**: Real-time product filtering via `ProductsProvider`
- **Image handling**: `cached_network_image` for efficient image loading

### Shopping Experience
- **Cart operations**: Add/remove items with provider state management  
- **Favorites**: Persistent favorite products management
- **Product sharing**: Native sharing via `share_plus`
- **WhatsApp integration**: Direct product ordering via WhatsApp deep links

### Screen Architecture
Key screens located in `lib/screens/`:
- `main.dart`: App entry point with provider setup and deep link handling
- `login_screen.dart` / `signup_screen.dart`: Authentication flows
- `profile_screen.dart`: User account management
- `cart_screen.dart`: Shopping cart with Paystack integration
- `product_details_screen.dart`: Individual product view
- `orders_screen.dart`: User order history
- `admin_orders_screen.dart`: Admin order management

## Development Guidelines

### Code Style
- Follow Flutter/Dart conventions
- Use `flutter_lints` package rules
- Maintain provider pattern for state management
- Implement proper error handling with user-friendly messages

### Firebase Security
- Never commit Firebase config files to public repos
- Implement proper Firestore security rules
- Use Firebase Auth for user verification

### API Integration
- Handle network errors gracefully with fallback to cached data
- Implement proper loading states in UI
- Use appropriate HTTP status code handling

### Testing
- Test widgets are located in `test/` directory
- Run tests with `flutter test`
- Ensure providers are properly tested with mock data

## Platform-Specific Notes

### Android
- Target SDK: Check `android/app/build.gradle.kts`
- Requires `android/key.properties` for app signing
- Deep linking configured in `AndroidManifest.xml`

### iOS
- Xcode project in `ios/` directory
- App Links configured for payment callbacks
- Icon generation via `flutter_launcher_icons` package

### Dependencies Overview
- **UI**: Material Design with custom theme
- **Network**: `http: ^1.5.0` for API calls
- **Local Storage**: `sqflite: ^2.4.2`, `shared_preferences: ^2.5.3`
- **Images**: `cached_network_image: ^3.4.1`, `carousel_slider: ^5.1.1`
- **External Integration**: `url_launcher: ^6.3.2`, `app_links: ^6.3.3`