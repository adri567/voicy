import Foundation

/// Disk-location helpers for the three real model families used by Voicy.
///
/// Pfade stammen aus der jeweiligen Library-Sources:
/// - WhisperKit: `HubApi.swift` → `~/Documents/huggingface/`
/// - MLX (swift-huggingface): `CacheLocationProvider.swift` → non-sandboxed macOS:
///   `~/.cache/huggingface/hub/`
/// - FluidAudio: `DownloadUtils.swift` → `~/Library/Application Support/FluidAudio/Models/`
///
/// Voicy ist nicht sandboxed (siehe Voicy.entitlements), daher gelten die obigen
/// non-sandboxed Defaults.
nonisolated enum ModelStorage {

    // MARK: - WhisperKit

    /// e.g. `~/Documents/huggingface/models/argmaxinc/whisperkit-coreml/openai_whisper-small/`
    static func whisperKitPath(model: String) -> URL {
        documentsHuggingFaceModels()
            .appendingPathComponent("argmaxinc", isDirectory: true)
            .appendingPathComponent("whisperkit-coreml", isDirectory: true)
            .appendingPathComponent(model, isDirectory: true)
    }

    // MARK: - FluidAudio (Parakeet)

    /// `~/Library/Application Support/FluidAudio/Models/`
    static func fluidAudioModelsRoot() -> URL {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
        return appSupport
            .appendingPathComponent("FluidAudio", isDirectory: true)
            .appendingPathComponent("Models", isDirectory: true)
    }

    // MARK: - MLX (HuggingFace hub)

    /// e.g. `~/.cache/huggingface/hub/models--mlx-community--gemma-4-e2b-it-4bit/`
    /// repoID is in the form `<org>/<repo>`.
    static func mlxPath(repoID: String) -> URL {
        let folder = "models--" + repoID.replacingOccurrences(of: "/", with: "--")
        return hubCacheRoot().appendingPathComponent(folder, isDirectory: true)
    }

    // MARK: - Generic file ops

    static func exists(at url: URL) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }

    static func remove(at url: URL) throws {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else { return }
        try fm.removeItem(at: url)
    }

    // MARK: - Private helpers

    private static func documentsHuggingFaceModels() -> URL {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fm.homeDirectoryForCurrentUser.appendingPathComponent("Documents", isDirectory: true)
        return docs
            .appendingPathComponent("huggingface", isDirectory: true)
            .appendingPathComponent("models", isDirectory: true)
    }

    private static func hubCacheRoot() -> URL {
        let env = ProcessInfo.processInfo.environment
        if let custom = env["HF_HUB_CACHE"], !custom.isEmpty {
            return URL(fileURLWithPath: NSString(string: custom).expandingTildeInPath, isDirectory: true)
        }
        if let hfHome = env["HF_HOME"], !hfHome.isEmpty {
            let expanded = NSString(string: hfHome).expandingTildeInPath
            return URL(fileURLWithPath: expanded, isDirectory: true)
                .appendingPathComponent("hub", isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cache", isDirectory: true)
            .appendingPathComponent("huggingface", isDirectory: true)
            .appendingPathComponent("hub", isDirectory: true)
    }
}
