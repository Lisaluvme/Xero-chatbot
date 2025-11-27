import Flutter
import UIKit
import Firebase
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Method to update widget data via shared UserDefaults
  private func updateWidgetData(data: [String: Any]) {
    let userDefaults = UserDefaults(suiteName: "group.com.mega.gensetassistant.ios")
    var widgetData = data
    widgetData["timestamp"] = Date().timeIntervalSince1970

    userDefaults?.set(widgetData, forKey: "currentGenset")

    // Force widget timeline refresh
    #if os(iOS)
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
    }
    #endif

    print("📱 Widget data updated: \(widgetData)")
  }
}
