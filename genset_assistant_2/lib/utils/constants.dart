class AppConstants {
  // API URLs
  static const String baseUrl = 'https://api.gensetassistant.com';
  static const String generatorStatusEndpoint = '$baseUrl/generator/status';
  static const String serviceRecordsEndpoint = '$baseUrl/service-records';

  // Contact Information
  static const String supportPhoneNumber = '+60123456789';
  static const String supportEmail = 'support@gensetassistant.com';
  static const String whatsappNumber = '+60123456789';
  static const String serviceCenterAddress = '123 Generator Street, Industrial Park, City 12345';

  // Notification Channels
  static const String serviceReminderChannelId = 'service_reminder_channel';
  static const String serviceReminderChannelName = 'Service Reminders';
  static const String serviceReminderChannelDescription = 'Reminders for generator service schedules';

  static const String maintenanceReminderChannelId = 'maintenance_reminder_channel';
  static const String maintenanceReminderChannelName = 'Maintenance Reminders';
  static const String maintenanceReminderChannelDescription = 'Reminders for generator maintenance tasks';

  static const String faultAlertChannelId = 'fault_alert_channel';
  static const String faultAlertChannelName = 'Fault Alerts';
  static const String faultAlertChannelDescription = 'Alerts for generator faults and issues';

  // Service Intervals (in days)
  static const int oilChangeInterval = 90; // 3 months
  static const int airFilterInterval = 180; // 6 months
  static const int fuelFilterInterval = 365; // 1 year
  static const int coolantChangeInterval = 730; // 2 years

  // Threshold Values
  static const int lowFuelThreshold = 25; // 25%
  static const double lowBatteryThreshold = 11.5; // 11.5V
  static const int highTempThreshold = 90; // 90°C
  static const int lowOilPressureThreshold = 20; // 20 PSI

  // Colors
  static const int primaryColor = 0xFF2196F3;
  static const int secondaryColor = 0xFF64B5F6;
  static const int accentColor = 0xFFFF9800;

  // App Information
  static const String appName = 'Genset Assistant 2';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'A Flutter application to assist users in learning about, maintaining, and troubleshooting generators.';

  // Default Messages
  static const String defaultWhatsAppMessage = 'Hello, I need assistance with my generator.';
  static const String defaultEmailSubject = 'Generator Support Request';
  static const String defaultEmailBody = 'Please describe your issue:';

  // Error Messages
  static const String networkErrorMessage = 'Unable to connect to the server. Please check your internet connection.';
  static const String apiErrorMessage = 'An error occurred while fetching data. Please try again later.';
  static const String permissionErrorMessage = 'Permission denied. Please grant the necessary permissions.';

  // Success Messages
  static const String serviceRecordSavedMessage = 'Service record saved successfully!';
  static const String reminderSetMessage = 'Reminder set successfully!';
  static const String contactInitiatedMessage = 'Opening contact application...';
}
