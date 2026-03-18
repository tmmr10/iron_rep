import Flutter
import UIKit
import UserNotifications
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var notificationChannel: FlutterMethodChannel?
  private var backupChannel: FlutterMethodChannel?
  private var pendingPickResult: FlutterResult?

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

      case "showOngoingNotification":
        guard let args = call.arguments as? [String: Any],
              let title = args["title"] as? String,
              let body = args["body"] as? String else {
          result(FlutterError(code: "BAD_ARGS", message: nil, details: nil))
          return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body

        let request = UNNotificationRequest(
          identifier: "workout_ongoing",
          content: content,
          trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
          DispatchQueue.main.async {
            if let error = error {
              result(FlutterError(code: "NOTIFICATION_ERROR", message: error.localizedDescription, details: nil))
            } else {
              result(true)
            }
          }
        }

      case "dismissOngoingNotification":
        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: ["workout_ongoing"])
        center.removePendingNotificationRequests(withIdentifiers: ["workout_ongoing"])
        result(true)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Set up platform channel for backup file handling
    backupChannel = FlutterMethodChannel(
      name: "com.tmmr.iron_rep/backup",
      binaryMessenger: controller.binaryMessenger
    )

    backupChannel?.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "pickBackupFile":
        self?.pickBackupFile(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Allow notifications to show as banners even when app is in foreground
    UNUserNotificationCenter.current().delegate = self

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle .ironrep files opened from Files, AirDrop, Mail, etc.
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    if url.pathExtension == "ironrep" {
      // Copy file to temp location accessible by Flutter
      let tempDir = NSTemporaryDirectory()
      let destUrl = URL(fileURLWithPath: tempDir).appendingPathComponent(url.lastPathComponent)
      try? FileManager.default.removeItem(at: destUrl)

      // Start security-scoped access if needed
      let accessing = url.startAccessingSecurityScopedResource()
      defer {
        if accessing { url.stopAccessingSecurityScopedResource() }
      }

      do {
        try FileManager.default.copyItem(at: url, to: destUrl)
        backupChannel?.invokeMethod("backupFileOpened", arguments: destUrl.path)
      } catch {
        // Fall back to super
      }
      return true
    }
    return super.application(app, open: url, options: options)
  }

  // Native document picker for .ironrep files
  private func pickBackupFile(result: @escaping FlutterResult) {
    pendingPickResult = result

    let picker: UIDocumentPickerViewController
    if #available(iOS 14.0, *) {
      if let ironrepType = UTType("com.tmmr.ironrep.backup") {
        picker = UIDocumentPickerViewController(forOpeningContentTypes: [ironrepType, .data])
      } else {
        picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data])
      }
    } else {
      picker = UIDocumentPickerViewController(documentTypes: ["com.tmmr.ironrep.backup", "public.data"], in: .open)
    }
    picker.delegate = self
    picker.allowsMultipleSelection = false

    if let vc = window?.rootViewController {
      vc.present(picker, animated: true)
    } else {
      result(FlutterError(code: "NO_VC", message: "No root view controller", details: nil))
      pendingPickResult = nil
    }
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

  // Handle notification tap — navigate to active workout
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let id = response.notification.request.identifier
    if id == "workout_ongoing" || id == "rest_timer" {
      notificationChannel?.invokeMethod("navigateTo", arguments: "/active-workout")
    }
    completionHandler()
  }
}

// MARK: - UIDocumentPickerDelegate
extension AppDelegate: UIDocumentPickerDelegate {
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let url = urls.first else {
      pendingPickResult?(nil)
      pendingPickResult = nil
      return
    }

    // Copy to temp so Flutter can access it
    let tempDir = NSTemporaryDirectory()
    let destUrl = URL(fileURLWithPath: tempDir).appendingPathComponent(url.lastPathComponent)
    try? FileManager.default.removeItem(at: destUrl)

    let accessing = url.startAccessingSecurityScopedResource()
    defer {
      if accessing { url.stopAccessingSecurityScopedResource() }
    }

    do {
      try FileManager.default.copyItem(at: url, to: destUrl)
      pendingPickResult?(destUrl.path)
    } catch {
      pendingPickResult?(FlutterError(code: "COPY_ERROR", message: error.localizedDescription, details: nil))
    }
    pendingPickResult = nil
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pendingPickResult?(nil)
    pendingPickResult = nil
  }
}
