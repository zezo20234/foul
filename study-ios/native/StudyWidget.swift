import ActivityKit
import WidgetKit
import SwiftUI

@main
struct StudyWidgetBundle: WidgetBundle {
    var body: some Widget { StudyLiveActivity() }
}

func fmt(_ s: Int) -> String {
    String(format: "%d:%02d", max(0, s) / 60, max(0, s) % 60)
}

struct TimerLabel: View {
    let state: StudyAttributes.ContentState
    var body: some View {
        if state.paused {
            Text(fmt(state.remaining)).monospacedDigit()
        } else {
            Text(state.endDate, style: .timer).monospacedDigit().multilineTextAlignment(.trailing)
        }
    }
}

struct Controls: View {
    let paused: Bool
    var body: some View {
        HStack(spacing: 12) {
            Button(intent: TogglePauseIntent()) {
                Image(systemName: paused ? "play.fill" : "pause.fill").frame(width: 48, height: 30)
            }
            Button(intent: SkipIntent()) {
                Image(systemName: "forward.fill").frame(width: 48, height: 30)
            }
        }
        .buttonStyle(.bordered)
        .tint(.white)
    }
}

struct StudyLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StudyAttributes.self) { context in
            VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.paused ? "Paused" : context.state.phase).font(.headline)
                    Text(context.state.cycleText).font(.caption).foregroundColor(.secondary)
                    if !context.attributes.subject.isEmpty {
                        Text(context.attributes.subject).font(.caption2).foregroundColor(.secondary)
                    }
                }
                Spacer()
                TimerLabel(state: context.state).font(.system(size: 40, weight: .light))
            }
            Controls(paused: context.state.paused)
            }
            .padding()
            .activityBackgroundTint(Color(red: 0.06, green: 0.46, blue: 0.43))
            .activitySystemActionForegroundColor(.white)
            .foregroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.paused ? "Paused" : context.state.phase).font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimerLabel(state: context.state).font(.title2)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.cycleText).font(.caption)
                        Spacer()
                        Controls(paused: context.state.paused)
                    }
                }
            } compactLeading: {
                Image(systemName: "clock")
            } compactTrailing: {
                TimerLabel(state: context.state).frame(maxWidth: 52)
            } minimal: {
                Image(systemName: "clock")
            }
        }
    }
}
