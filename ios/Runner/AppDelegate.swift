import Flutter
import UIKit
import UserNotifications
import UniformTypeIdentifiers
import ActivityKit

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

      case "startLiveActivity":
        guard let args = call.arguments as? [String: Any],
              let seconds = args["seconds"] as? Int,
              let exerciseName = args["exerciseName"] as? String else {
          result(FlutterError(code: "BAD_ARGS", message: nil, details: nil))
          return
        }
        let nextExerciseName = args["nextExerciseName"] as? String ?? ""
        self.updateWorkoutLiveActivity(
          exerciseName: exerciseName, nextExerciseName: nextExerciseName,
          currentSet: 0, totalSets: 0, isResting: true,
          timerSeconds: seconds, result: result
        )

      case "endLiveActivity":
        // Clear rest state first so the update isn't blocked by the guard
        self.isCurrentlyResting = false
        self.updateWorkoutLiveActivity(
          exerciseName: self.lastExerciseName, nextExerciseName: self.lastNextExerciseName,
          currentSet: self.lastCurrentSet, totalSets: self.lastTotalSets, isResting: false,
          timerSeconds: nil, result: result
        )

      case "startWorkoutActivity":
        guard let args = call.arguments as? [String: Any],
              let workoutName = args["workoutName"] as? String else {
          result(FlutterError(code: "BAD_ARGS", message: nil, details: nil))
          return
        }
        let startedAtMs = args["startedAtMs"] as? Int
        self.startWorkoutActivity(workoutName: workoutName, startedAtMs: startedAtMs, result: result)

      case "updateWorkoutActivity":
        guard let args = call.arguments as? [String: Any],
              let exerciseName = args["exerciseName"] as? String else {
          result(FlutterError(code: "BAD_ARGS", message: nil, details: nil))
          return
        }
        let nextExerciseName = args["nextExerciseName"] as? String ?? ""
        let currentSet = args["currentSet"] as? Int ?? 0
        let totalSets = args["totalSets"] as? Int ?? 0
        self.updateWorkoutLiveActivity(
          exerciseName: exerciseName, nextExerciseName: nextExerciseName,
          currentSet: currentSet, totalSets: totalSets, isResting: false,
          timerSeconds: nil, result: result
        )

      case "pauseWorkoutActivity":
        guard let args = call.arguments as? [String: Any],
              let elapsedSeconds = args["elapsedSeconds"] as? Int else {
          result(FlutterError(code: "BAD_ARGS", message: nil, details: nil))
          return
        }
        self.pauseWorkoutActivity(elapsedSeconds: elapsedSeconds, result: result)

      case "resumeWorkoutActivity":
        guard let args = call.arguments as? [String: Any],
              let elapsedSeconds = args["elapsedSeconds"] as? Int else {
          result(FlutterError(code: "BAD_ARGS", message: nil, details: nil))
          return
        }
        self.resumeWorkoutActivity(elapsedSeconds: elapsedSeconds, result: result)

      case "endWorkoutActivity":
        self.endWorkoutActivity(result: result)

      case "isLiveActivityEnabled":
        if #available(iOS 16.2, *) {
          result(ActivityAuthorizationInfo().areActivitiesEnabled)
        } else {
          result(false)
        }

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

  // MARK: - Live Activity

  private var workoutStartTime: Date?

  private func startWorkoutActivity(workoutName: String, startedAtMs: Int?, result: @escaping FlutterResult) {
    if #available(iOS 16.2, *) {
      // Set workoutStartTime
      if let ms = startedAtMs {
        workoutStartTime = Date(timeIntervalSince1970: Double(ms) / 1000.0)
      }

      // If an active activity already exists, don't create a new one
      let hasActive = Activity<RestTimerAttributes>.activities.contains { $0.activityState == .active }
      if hasActive {
        result(true)
        return
      }

      let startTime: Date
      if let ms = startedAtMs {
        startTime = Date(timeIntervalSince1970: Double(ms) / 1000.0)
      } else {
        startTime = Date()
      }
      workoutStartTime = startTime
      let attributes = RestTimerAttributes(workoutName: workoutName)
      let state = RestTimerAttributes.ContentState(
        exerciseName: workoutName,
        nextExerciseName: "",
        currentSet: 0,
        totalSets: 0,
        isResting: false,
        isPaused: false,
        timerEndTime: nil,
        timerStartTime: nil,
        workoutStartTime: startTime,
        pausedElapsedSeconds: nil
      )

      do {
        let content = ActivityContent(state: state, staleDate: nil)
        _ = try Activity.request(
          attributes: attributes,
          content: content,
          pushType: nil
        )
        result(true)
      } catch {
        result(false)
      }
    } else {
      result(false)
    }
  }

  private var lastExerciseName: String = ""
  private var lastNextExerciseName: String = ""
  private var lastCurrentSet: Int = 0
  private var lastTotalSets: Int = 0
  private var isCurrentlyResting: Bool = false
  private var isCurrentlyPaused: Bool = false

  private func updateWorkoutLiveActivity(
    exerciseName: String, nextExerciseName: String,
    currentSet: Int, totalSets: Int, isResting: Bool,
    timerSeconds: Int?, result: @escaping FlutterResult
  ) {
    if #available(iOS 16.2, *) {
      // Ignore updates while rest timer or pause is active
      // (Flutter rebuilds trigger updateWorkoutActivity that would overwrite the state)
      if (isCurrentlyResting || isCurrentlyPaused) && !isResting && timerSeconds == nil {
        result(true)
        return
      }

      // Track rest state
      isCurrentlyResting = isResting

      // Save last known exercise state for restoring after rest timer
      if !exerciseName.isEmpty {
        lastExerciseName = exerciseName
        lastNextExerciseName = nextExerciseName
        if !isResting {
          lastCurrentSet = currentSet
          lastTotalSets = totalSets
        }
      }

      let now = Date()
      var timerStart: Date? = nil
      var timerEnd: Date? = nil
      if isResting, let seconds = timerSeconds {
        timerStart = now
        timerEnd = now.addingTimeInterval(TimeInterval(seconds))
      }

      // Use provided name, or fall back to last known
      let displayName = exerciseName.isEmpty ? lastExerciseName : exerciseName
      let displayNext = nextExerciseName.isEmpty && !isResting ? lastNextExerciseName : nextExerciseName

      let state = RestTimerAttributes.ContentState(
        exerciseName: displayName.isEmpty ? "Training" : displayName,
        nextExerciseName: displayNext,
        currentSet: currentSet > 0 ? currentSet : lastCurrentSet,
        totalSets: totalSets > 0 ? totalSets : lastTotalSets,
        isResting: isResting,
        isPaused: false,
        timerEndTime: timerEnd,
        timerStartTime: timerStart,
        workoutStartTime: workoutStartTime ?? now,
        pausedElapsedSeconds: nil
      )

      if workoutStartTime == nil { workoutStartTime = now }

      let content = ActivityContent(state: state, staleDate: timerEnd)

      if let activity = Activity<RestTimerAttributes>.activities.first(where: { $0.activityState == .active }) {
        Task {
          await activity.update(content)
          DispatchQueue.main.async { result(true) }
        }
      } else {
        let attributes = RestTimerAttributes(workoutName: displayName)
        do {
          _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
          result(true)
        } catch {
          result(false)
        }
      }
    } else {
      result(false)
    }
  }

  private func endWorkoutActivity(result: @escaping FlutterResult) {
    if #available(iOS 16.2, *) {
      workoutStartTime = nil
      Task {
        for activity in Activity<RestTimerAttributes>.activities {
          await activity.end(nil, dismissalPolicy: .immediate)
        }
        DispatchQueue.main.async {
          result(true)
        }
      }
    } else {
      result(true)
    }
  }

  private func pauseWorkoutActivity(elapsedSeconds: Int, result: @escaping FlutterResult) {
    isCurrentlyPaused = true
    if #available(iOS 16.2, *) {
      let displayName = lastExerciseName.isEmpty ? "Training" : lastExerciseName
      let state = RestTimerAttributes.ContentState(
        exerciseName: displayName,
        nextExerciseName: lastNextExerciseName,
        currentSet: lastCurrentSet,
        totalSets: lastTotalSets,
        isResting: false,
        isPaused: true,
        timerEndTime: nil,
        timerStartTime: nil,
        workoutStartTime: workoutStartTime ?? Date(),
        pausedElapsedSeconds: elapsedSeconds
      )
      let content = ActivityContent(state: state, staleDate: nil)
      if let activity = Activity<RestTimerAttributes>.activities.first(where: { $0.activityState == .active }) {
        Task {
          await activity.update(content)
          DispatchQueue.main.async { result(true) }
        }
      } else {
        result(false)
      }
    } else {
      result(false)
    }
  }

  private func resumeWorkoutActivity(elapsedSeconds: Int, result: @escaping FlutterResult) {
    isCurrentlyPaused = false
    if #available(iOS 16.2, *) {
      // Recalculate workoutStartTime so count-up timer shows correct elapsed time
      let now = Date()
      workoutStartTime = now.addingTimeInterval(-TimeInterval(elapsedSeconds))
      let displayName = lastExerciseName.isEmpty ? "Training" : lastExerciseName
      let state = RestTimerAttributes.ContentState(
        exerciseName: displayName,
        nextExerciseName: lastNextExerciseName,
        currentSet: lastCurrentSet,
        totalSets: lastTotalSets,
        isResting: false,
        isPaused: false,
        timerEndTime: nil,
        timerStartTime: nil,
        workoutStartTime: workoutStartTime!,
        pausedElapsedSeconds: nil
      )
      let content = ActivityContent(state: state, staleDate: nil)
      if let activity = Activity<RestTimerAttributes>.activities.first(where: { $0.activityState == .active }) {
        Task {
          await activity.update(content)
          DispatchQueue.main.async { result(true) }
        }
      } else {
        result(false)
      }
    } else {
      result(false)
    }
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
