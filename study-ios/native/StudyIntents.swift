import AppIntents
import ActivityKit
import Foundation

extension Notification.Name {
    static let studyLiveAction = Notification.Name("studyLiveAction")
}

@available(iOS 17.0, *)
struct TogglePauseIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Pause or resume"
    func perform() async throws -> some IntentResult {
        // Update the lock screen right away, without waiting for the web page.
        if let a = Activity<StudyAttributes>.activities.first {
            var st = a.content.state
            if st.paused {
                st.endDate = Date().addingTimeInterval(Double(st.remaining))
                st.paused = false
            } else {
                st.remaining = max(0, Int(st.endDate.timeIntervalSinceNow))
                st.paused = true
            }
            await a.update(ActivityContent(state: st, staleDate: nil))
        }
        NotificationCenter.default.post(name: .studyLiveAction, object: nil, userInfo: ["action": "toggle"])
        return .result()
    }
}

@available(iOS 17.0, *)
struct SkipIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Skip phase"
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .studyLiveAction, object: nil, userInfo: ["action": "skip"])
        return .result()
    }
}
