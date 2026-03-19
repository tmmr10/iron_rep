import ActivityKit
import Foundation

struct RestTimerAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var exerciseName: String
    var nextExerciseName: String
    var currentSet: Int
    var totalSets: Int
    var isResting: Bool
    var isPaused: Bool
    var timerEndTime: Date?
    var timerStartTime: Date?
    var workoutStartTime: Date
    var pausedElapsedSeconds: Int?
  }

  var workoutName: String
}
