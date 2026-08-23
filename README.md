# Pestzone Spray

[![Flutter Version](https://img.shields.io/badge/Flutter-v3.11.5-blue.svg)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green.svg)](https://flutter.dev)

**Pestzone Spray** is a modern, high-performance Flutter application designed for the intelligent management of pest traps and automated watering systems. Built with real-time IoT integration via MQTT, it provides farmers and greenhouse operators with precise control and monitoring capabilities directly from their mobile devices.

---

## Key Features

- **Real-time Monitoring**: Track battery levels, network status, and operational health of all connected devices.
- **Remote Control**: Manually toggle UV pest-attraction lights and water pump systems with zero latency.
- **Smart Analytics**: Visualize historical data and activity logs using dynamic charts (powered by `fl_chart`).
- **Adaptive UI**: Seamlessly switch between light and dark modes with a premium glassmorphism design.
- **Device Provisioning**: Easily configure and reset device WiFi credentials using the built-in setup wizard.
- **Offline Resilience**: Smart command queuing ensures your instructions are sent as soon as the connection is restored.

---

## Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Communication**: [MQTT Client](https://pub.dev/packages/mqtt_client)
- **Storage**: [Shared Preferences](https://pub.dev/packages/shared_preferences)
- **Visualization**: [FL Chart](https://pub.dev/packages/fl_chart)
- **Typography**: [Google Fonts](https://pub.dev/packages/google_fonts) (Outfit/Inter)

---

## Getting Started

### Prerequisites

- Flutter SDK: `^3.11.5`
- Dart SDK: `^3.1.0`
- An active MQTT Broker (Default: `broker.hivemq.com`)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/pest_trap_watering.git
   cd pest_trap_watering
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the application:**
   ```bash
   flutter run
   ```

---

## 📡 IoT & MQTT Configuration

The application communicates with devices using the following topic structure:

- **Telemetry (Inbound)**: `tanisolution/+/telemetry`
- **Commands (Outbound)**: `tanisolution/{device_id}/command`

### Payload Examples

**Telemetry Status:**
```json
{
  "bat": 85,
  "is_night": true,
  "uv": 1,
  "pump": 0
}
```

**Command Format:**
```json
{
  "action": "uv_on"
}
```

---

## Project Structure

```text
lib/
├── models/         # Data models for Devices and Logs
├── providers/      # State management (Device & Theme)
├── screens/        # UI Layers (Home, Control, Log, etc.)
├── services/       # MQTT and Core Logic services
├── theme/          # Custom styling and design system
└── main.dart       # App entry point & Router
```

---

## Contributing

Contributions are welcome! If you'd like to improve the app, please feel free to:
1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request