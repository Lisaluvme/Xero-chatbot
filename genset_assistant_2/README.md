# Genset Assistant 2

Genset Assistant 2 is a Flutter application designed to help users learn about operating, maintaining, and troubleshooting generators. The app provides features for recording service dates with reminders, receiving live status updates via API, and contacting the office through WhatsApp.

## Features

- **Learn**: Access information on how to operate generators, including navigation to different sections of the learning material.
- **Maintenance**: Get tips and schedules for maintaining generators to ensure optimal performance.
- **Troubleshooting**: Find guidance on troubleshooting common generator issues with step-by-step instructions.
- **Service Records**: Record the last service date and set reminders for upcoming service intervals, with options to save and retrieve service records.
- **Live Status**: View live status updates of the generator's parameters such as location, run hours, and faults, with real-time data fetched from the API.
- **Contact**: Easily contact the office via WhatsApp with a single button click.

## Project Structure

```
genset_assistant_2
├── lib
│   ├── main.dart
│   ├── features
│   │   ├── learn
│   │   │   └── learn_page.dart
│   │   ├── maintenance
│   │   │   └── maintenance_page.dart
│   │   ├── troubleshooting
│   │   │   └── troubleshooting_page.dart
│   │   ├── service_records
│   │   │   └── service_records_page.dart
│   │   ├── live_status
│   │   │   └── live_status_page.dart
│   │   └── contact
│   │       └── contact_page.dart
│   ├── models
│   │   └── generator_model.dart
│   ├── services
│   │   ├── api_service.dart
│   │   └── notification_service.dart
│   └── utils
│       └── constants.dart
├── pubspec.yaml
└── README.md
```

## Setup Instructions

1. Clone the repository:
   ```
   git clone <repository-url>
   ```
2. Navigate to the project directory:
   ```
   cd genset_assistant_2
   ```
3. Install dependencies:
   ```
   flutter pub get
   ```
4. Run the application:
   ```
   flutter run
   ```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any enhancements or bug fixes.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.