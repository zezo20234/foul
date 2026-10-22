import Foundation

// Used automatically if the AlarmKit code fails to compile.
enum AlarmBridge {
    static func set(_ items: [(Double, String)]) async -> Bool { return false }
}
