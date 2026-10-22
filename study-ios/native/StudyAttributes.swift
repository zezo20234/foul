import ActivityKit
import Foundation

struct StudyAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var phase: String
        var endDate: Date
        var paused: Bool
        var remaining: Int
        var cycleText: String
    }
    var subject: String
}
