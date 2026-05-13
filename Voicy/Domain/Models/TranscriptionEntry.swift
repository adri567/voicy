import Foundation
import SwiftData

@Model
final class TranscriptionEntry {
    var id: UUID
    var text: String
    var createdAt: Date
    var duration: TimeInterval
    var engineRaw: String
    var corrected: Bool
    var targetAppName: String?
    var targetAppBundleID: String?
    var targetWindowTitle: String?

    init(
        text: String,
        createdAt: Date,
        duration: TimeInterval,
        engine: TranscriptionEngine,
        corrected: Bool,
        target: TargetAppSnapshot? = nil
    ) {
        self.id = UUID()
        self.text = text
        self.createdAt = createdAt
        self.duration = duration
        self.engineRaw = engine.rawValue
        self.corrected = corrected
        self.targetAppName = target?.appName
        self.targetAppBundleID = target?.bundleID
        self.targetWindowTitle = target?.windowTitle
    }

    var engine: TranscriptionEngine {
        TranscriptionEngine(rawValue: engineRaw) ?? .whisper
    }
}
