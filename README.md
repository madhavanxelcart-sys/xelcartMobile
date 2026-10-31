# Xelcart Mobile

Xelcart Mobile is a Flutter seller app for managing store onboarding, inventory, orders, and delivery workflows.

## Features

- Phone sign-in with a demo OTP flow.
- Four-step seller onboarding for business details, social channels, delivery setup, and store policies.
- Inventory dashboard with product creation, editing, and stock management.
- Order dashboard with manual order entry, conversation import, order details, and status updates.
- Delivery details and shipping-label generation with simulated Bluetooth printing.
- Settings for social channels, payment providers, and logistics backend URLs.

## Current implementation

This project uses demo authentication and mock, session-local repositories. Orders, inventory changes, onboarding data, and integration settings are not persisted to a remote backend. Signing out resets session data.

The demo verification code is `123456`. The default conversation parser runs locally, and Bluetooth printing is simulated. Configuring an integration URL does not establish a verified provider connection.

See [Fulfillment integration boundaries](docs/fulfillment_integrations.md) for backend contracts, label formats, and the work required to connect production services.

## Getting started

Install Flutter with a bundled Dart SDK compatible with `^3.13.7`, as required by `pubspec.yaml`. Set up the Android or iOS toolchain for your target device.

```sh
git clone https://github.com/madhavanxelcart-sys/xelcartMobile.git
cd xelcartMobile
flutter doctor
flutter pub get
flutter run
```

Start an emulator or connect a device before running the app. Android uses Gradle 9.3.1, downloaded automatically by the Gradle wrapper on first use.

## Development checks

```sh
flutter analyze
flutter test
```

The test suite covers authentication, onboarding, inventory, orders, delivery details, mock repositories, and integration services.

## Optional order-parsing backend

To use an HTTPS parsing service instead of the default local parser:

```sh
flutter run --dart-define=AI_ORDER_PARSER_URL=https://your-backend.example/orders/parse
```

Implement the contract described in the [integration guide](docs/fulfillment_integrations.md). Keep provider credentials on the server; do not put API secrets in Flutter build flags.

## Project structure

| Path | Contents |
| --- | --- |
| `lib/core/` | Shared routing, theme, services, utilities, and widgets |
| `lib/features/` | Authentication, onboarding, inventory, orders, delivery, and settings |
| `assets/` | App images and SVG icons |
| `design_refs/` | Reference designs |
| `test/` | Automated tests |
| `docs/` | Integration documentation |
| `android/`, `ios/` | Native mobile project configuration |
