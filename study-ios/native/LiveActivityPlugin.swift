import Foundation
import Capacitor
import ActivityKit

@objc(LiveActivityPlugin)
public class LiveActivityPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "LiveActivityPlugin"
    public let jsName = "LiveActivity"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "start", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "end", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setAlarms", returnType: CAPPluginReturnPromise)
    ]

    public override func load() {
        NotificationCenter.default.addObserver(forName: .studyLiveAction, object: nil, queue: .main) { [weak self] note in
            let action = (note.userInfo?["action"] as? String) ?? ""
            self?.notifyListeners("liveAction", data: ["action": action], retainUntilConsumed: true)
        }
    }

    @objc func setAlarms(_ call: CAPPluginCall) {
        let raw = call.getArray("alarms", JSObject.self) ?? []
        let items: [(Double, String)] = raw.map {
            (($0["endMs"] as? NSNumber)?.doubleValue ?? 0, ($0["title"] as? String) ?? "Timer finished")
        }
        Task {
            let ok = await AlarmBridge.set(items)
            call.resolve(["scheduled": ok])
        }
    }

    @objc func start(_ call: CAPPluginCall) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            call.reject("Live Activities are turned off in Settings")
            return
        }
        let endMs = call.getDouble("endMs") ?? (Date().timeIntervalSince1970 * 1000)
        let state = StudyAttributes.ContentState(
            phase: call.getString("phase") ?? "Focus",
            endDate: Date(timeIntervalSince1970: endMs / 1000),
            paused: call.getBool("paused") ?? false,
            remaining: call.getInt("remaining") ?? 0,
            cycleText: call.getString("cycleText") ?? ""
        )
        let content = ActivityContent(state: state, staleDate: nil)
        if let existing = Activity<StudyAttributes>.activities.first {
            Task {
                await existing.update(content)
                call.resolve()
            }
        } else {
            do {
                _ = try Activity<StudyAttributes>.request(
                    attributes: StudyAttributes(subject: call.getString("subject") ?? ""),
                    content: content,
                    pushType: nil
                )
                call.resolve()
            } catch {
                call.reject(error.localizedDescription)
            }
        }
    }

    @objc func end(_ call: CAPPluginCall) {
        Task {
            for a in Activity<StudyAttributes>.activities {
                await a.end(nil, dismissalPolicy: .immediate)
            }
            call.resolve()
        }
    }
}
