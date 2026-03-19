import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.2, *)
private struct TimerDisplay: View {
  let state: RestTimerAttributes.ContentState
  let large: Bool

  var body: some View {
    if state.isPaused {
      // Show frozen elapsed time
      let elapsed = state.pausedElapsedSeconds ?? 0
      let m = elapsed / 60
      let s = elapsed % 60
      Text(String(format: "%02d:%02d", m, s))
        .font(.system(size: large ? 15 : 14, weight: .bold, design: .monospaced))
        .foregroundColor(.yellow)
        .monospacedDigit()
    } else if state.isResting, let start = state.timerStartTime, let end = state.timerEndTime {
      Text(timerInterval: start...end, countsDown: true)
        .font(.system(size: large ? 15 : 14, weight: .bold, design: .monospaced))
        .foregroundColor(.orange)
        .monospacedDigit()
    } else {
      Text(timerInterval: state.workoutStartTime...Date.distantFuture, countsDown: false)
        .font(.system(size: large ? 15 : 14, weight: .bold, design: .monospaced))
        .foregroundColor(.white)
        .monospacedDigit()
    }
  }
}

@available(iOS 16.2, *)
private struct LockScreenView: View {
  let state: RestTimerAttributes.ContentState

  private var icon: String {
    if state.isPaused { return "pause.fill" }
    if state.isResting { return "timer" }
    return "figure.strengthtraining.traditional"
  }

  private var iconColor: Color {
    if state.isPaused { return .yellow }
    if state.isResting { return .orange }
    return .green
  }

  private var subtitle: String {
    if state.isPaused {
      return "Pausiert"
    }
    if state.isResting {
      return state.nextExerciseName.isEmpty ? "Letzte Übung" : "Nächste: \(state.nextExerciseName)"
    }
    var parts: [String] = []
    if state.totalSets > 0 {
      parts.append("Satz \(state.currentSet)/\(state.totalSets)")
    }
    if !state.nextExerciseName.isEmpty {
      parts.append("→ \(state.nextExerciseName)")
    }
    if parts.isEmpty {
      return "Training aktiv"
    }
    return parts.joined(separator: "  ")
  }

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: icon)
        .font(.system(size: 22))
        .foregroundColor(iconColor)
        .frame(width: 28)
      VStack(alignment: .leading, spacing: 4) {
        Text(state.exerciseName)
          .font(.system(size: 15, weight: .semibold))
          .foregroundColor(.white)
          .lineLimit(1)
        Text(subtitle)
          .font(.system(size: 13))
          .foregroundColor(.white.opacity(0.6))
          .lineLimit(1)
          .minimumScaleFactor(0.75)
      }
      Spacer()
      TimerDisplay(state: state, large: true)
        .multilineTextAlignment(.trailing)
        .frame(width: 58, alignment: .trailing)
    }
  }
}

@available(iOS 16.2, *)
struct RestTimerLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: RestTimerAttributes.self) { context in
      LockScreenView(state: context.state)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.black)

    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          VStack(alignment: .leading, spacing: 3) {
            Text(context.state.exerciseName)
              .font(.system(size: 16, weight: .semibold))
            if context.state.isPaused {
              Text("Pausiert")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.yellow)
            } else if context.state.isResting {
              if !context.state.nextExerciseName.isEmpty {
                Text("Nächste: \(context.state.nextExerciseName)")
                  .font(.system(size: 13))
                  .foregroundColor(.secondary)
              }
            } else if context.state.totalSets > 0 {
              HStack(spacing: 6) {
                Text("Satz \(context.state.currentSet)/\(context.state.totalSets)")
                  .font(.system(size: 13, weight: .medium))
                  .foregroundColor(.secondary)
                if !context.state.nextExerciseName.isEmpty {
                  Text("→ \(context.state.nextExerciseName)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary.opacity(0.7))
                }
              }
            }
          }
        }
        DynamicIslandExpandedRegion(.trailing) {
          TimerDisplay(state: context.state, large: true)
        }
        DynamicIslandExpandedRegion(.bottom) {}
      } compactLeading: {
        Image(systemName: context.state.isPaused ? "pause.fill" : (context.state.isResting ? "timer" : "figure.strengthtraining.traditional"))
          .foregroundColor(context.state.isPaused ? .yellow : (context.state.isResting ? .orange : .green))
      } compactTrailing: {
        TimerDisplay(state: context.state, large: false)
          .frame(width: 52)
      } minimal: {
        Image(systemName: context.state.isPaused ? "pause.fill" : (context.state.isResting ? "timer" : "figure.strengthtraining.traditional"))
          .foregroundColor(context.state.isPaused ? .yellow : (context.state.isResting ? .orange : .green))
      }
    }
  }
}

@main
struct RestTimerLiveActivityBundle: WidgetBundle {
  var body: some Widget {
    if #available(iOS 16.2, *) {
      RestTimerLiveActivity()
    }
  }
}
