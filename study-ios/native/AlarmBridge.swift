import Foundation
#if canImport(AlarmKit)
import AlarmKit
import SwiftUI

@available(iOS 26.0, *)
struct StudyAlarmMeta: AlarmMetadata {}

enum AlarmBridge {
    /// items = (end time in ms since 1970, title). Returns true when system alarms were scheduled.
    static func set(_ items: [(Double, String)]) async -> Bool {
        if #available(iOS 26.0, *) {
            do {
                let manager = AlarmManager.shared
                let state = try await manager.requestAuthorization()
                guard state == .authorized else { return false }
                for a in try manager.alarms where a.state != .alerting {
                    try? manager.cancel(id: a.id)
                }
                for (endMs, title) in items {
                    let stop = AlarmButton(text: "Stop", textColor: .white, systemImageName: "stop.circle")
                    let alert = AlarmPresentation.Alert(title: LocalizedStringResource(stringLiteral: title), stopButton: stop)
                    let attrs = AlarmAttributes<StudyAlarmMeta>(presentation: AlarmPresentation(alert: alert), tintColor: Color.teal)
                    let config = AlarmManager.AlarmConfiguration.alarm(
                        schedule: Alarm.Schedule.fixed(Date(timeIntervalSince1970: endMs / 1000)),
                        attributes: attrs
                    )
                    _ = try await manager.schedule(id: UUID(), configuration: config)
                }
                return true
            } catch {
                return false
            }
        }
        return false
    }
}
#else
enum AlarmBridge {
    static func set(_ items: [(Double, String)]) async -> Bool { return false }
}
#endif
