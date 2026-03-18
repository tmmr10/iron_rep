import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var notificationChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Set up platform channel for native notifications
    let controller = window?.rootViewController as! FlutterViewController
    notificationChannel = FlutterMethodChannel(
      name: "com.tmmr.iron_rep/notifications",
      binaryMessenger: controller.binaryMessenger
    )

    notificationChannel?.setMethodCallHandler { (call, result) in
      switch call.method {
      case "requestPermission":
        UNUserNotificationCenter.current().requestAuthorization(
          options: [.alert, .sound, .badge]
        ) { granted, error in
          DispatchQueue.main.async {
            result(granted)
          }
        }

      case "scheduleTimer":
        guard let args = call.arguments as? [String: Any],
              let seconds = args["seconds"] as? Int,
              let title = args["title"] as? String,
              let body = args["body"] as? String else {
          result(FlutterError(code: "BAD_ARGS", message: nil, details: nil))
          return
        }

        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
          timeInterval: TimeInterval(seconds),
          repeats: false
        )

        let request = UNNotificationRequest(
          identifier: "rest_timer",
          content: content,
          trigger: trigger
        )

        center.add(request) { error in
          DispatchQueue.main.async {
            if let error = error {
              result(FlutterError(code: "SCHEDULE_ERROR", message: error.localizedDescription, details: nil))
            } else {
              result(true)
            }
          }
        }

      case "cancelTimer":
        UNUserNotificationCenter.current().removePendingNotificationRequests(
          withIdentifiers: ["rest_timer"]
        )
        result(true)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Allow notifications to show as banners even when app is in foreground
    UNUserNotificationCenter.current().delegate = self

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Show notification banner even when app is in foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound])
    } else {
      completionHandler([.alert, .sound])
    }
  }
}
