import CoreML
import Foundation
import OSLog
import FluidAudio

/// Speaker diarization via FluidAudio's LS-EEND model. We deliberately *don't*
/// use Sortformer here: the FluidAudio-shipped Sortformer mlpackages
/// (`Sortformer_v2.mlmodelc`, `Sortformer_v2.1.mlmodelc`) declare
/// `chunk_pre_encoder_embs_out` as both an input and an output tensor — on
/// macOS 26 BNNS refuses to compile that ("Inputs and outputs must be
/// distinct"), so the install completes the download but then crashes inside
/// `MLModel(contentsOf:)`. LS-EEND is a different model architecture and
/// compiles cleanly.
///
/// The diarizer itself is non-thread-safe by design; the actor serializes all
/// access. `processComplete` is synchronous + CPU-bound; one call blocks the
/// actor for the full inference, which is fine because the Transcribe pipeline
/// only diarizes one file at a time.
actor FluidAudioDiarizationService: DiarizationService {

    private var diarizer: LSEENDDiarizer?
    /// In-flight load, shared by concurrent `loadModel()` callers so the model
    /// is loaded once instead of duplicated across overlapping calls.
    private var loadTask: Task<Void, Error>?

    init() {}

    func loadModel() async throws {
        if diarizer != nil { return }
        if let loadTask { return try await loadTask.value }
        let task = Task<Void, Error> { try await self.performLoad() }
        loadTask = task
        defer { loadTask = nil }
        try await task.value
    }

    private func performLoad() async throws {
        guard diarizer == nil else { return }
        guard isModelInstalled() else {
            Log.diarization.debug("LS-EEND: skipping auto-load — model not on disk")
            return
        }
        Log.diarization.debug("LS-EEND: loading from cache (\(String(describing: Self.activeVariant), privacy: .public), \(String(describing: Self.activeStepSize), privacy: .public))")
        let model = try await LSEENDModel.loadFromHuggingFace(
            variant: Self.activeVariant,
            stepSize: Self.activeStepSize,
            cacheDirectory: nil,
            computeUnits: .cpuOnly,
            progressHandler: nil
        )
        let d = LSEENDDiarizer(timelineConfig: nil)
        try d.initialize(model: model)
        diarizer = d
        Log.diarization.debug("LS-EEND: model ready")
    }

    // MARK: - DiarizationService

    func diarize(at url: URL) async throws -> [DiarizationSegment] {
        if diarizer == nil {
            try await loadModel()
        }
        guard let diarizer else { throw DiarizationError.modelNotLoaded }

        let timeline = try diarizer.processComplete(audioFileURL: url)

        var result: [DiarizationSegment] = []
        for (speakerIndex, speaker) in timeline.speakers {
            for seg in speaker.finalizedSegments {
                result.append(
                    DiarizationSegment(
                        start: TimeInterval(seg.startTime),
                        end: TimeInterval(seg.endTime),
                        speakerId: speakerIndex
                    )
                )
            }
        }
        return result.sorted(by: { $0.start < $1.start })
    }

    nonisolated func isModelInstalled() -> Bool {
        Self.isInstalled(variant: Self.activeVariant, stepSize: Self.activeStepSize)
    }

    func installModel(progress: @escaping @Sendable (DownloadPhase) -> Void) async throws {
        if isModelInstalled(), diarizer != nil { return }
        Log.diarization.debug("LS-EEND: install start — fetching from HuggingFace")
        progress(.preparing)
        do {
            let model = try await LSEENDModel.loadFromHuggingFace(
                variant: Self.activeVariant,
                stepSize: Self.activeStepSize,
                cacheDirectory: nil,
                computeUnits: .cpuOnly,
                progressHandler: { p in
                    Log.diarization.debug("LS-EEND: progress \(p.fractionCompleted * 100, format: .fixed(precision: 0))% (\(String(describing: p.phase), privacy: .public))")
                    progress(.downloading(p.fractionCompleted))
                }
            )
            Log.diarization.debug("LS-EEND: download finished, initializing diarizer")
            progress(.finalizing)
            let d = LSEENDDiarizer(timelineConfig: nil)
            try d.initialize(model: model)
            diarizer = d
            Log.diarization.debug("LS-EEND: model installed")
        } catch {
            Log.diarization.error("LS-EEND: install failed: \(String(describing: error), privacy: .public)")
            throw error
        }
    }

    func removeModel() async throws {
        diarizer = nil
        try Self.remove(variant: Self.activeVariant)
        Log.diarization.debug("LS-EEND: model removed from disk")
    }

    // MARK: - Static API

    /// Currently selected LS-EEND variant. DIHARD-3 trained — best generic
    /// quality across diverse audio types.
    nonisolated static let activeVariant: ModelNames.LSEEND.Variant = .dihard3

    /// Step size in milliseconds. 100ms is the finest grain — highest model
    /// frame-rate, best segment boundaries.
    nonisolated static let activeStepSize: ModelNames.LSEEND.StepSize = .step100ms

    nonisolated static func isInstalled(
        variant: ModelNames.LSEEND.Variant,
        stepSize: ModelNames.LSEEND.StepSize
    ) -> Bool {
        let modelURL = modelFileURL(variant: variant, stepSize: stepSize)
        return FileManager.default.fileExists(atPath: modelURL.path)
    }

    nonisolated static func remove(variant: ModelNames.LSEEND.Variant) throws {
        let repoDir = cacheDirectory().appendingPathComponent(variant.repo.folderName)
        try ModelStorage.remove(at: repoDir)
    }

    /// Compose the exact path `LSEENDModel.loadFromHuggingFace` writes to.
    /// FluidAudio appends `repo.folderName`, then (if present) `repo.subPath`,
    /// then the per-step `<name>_<step>.mlmodelc` file.
    nonisolated private static func modelFileURL(
        variant: ModelNames.LSEEND.Variant,
        stepSize: ModelNames.LSEEND.StepSize
    ) -> URL {
        let repo = variant.repo
        let modelRelPath = variant.fileName(forStep: stepSize)
        let fullRelPath = repo.subPath.map { "\($0)/\(modelRelPath)" } ?? modelRelPath
        return cacheDirectory()
            .appendingPathComponent(repo.folderName)
            .appendingPathComponent(fullRelPath)
    }

    nonisolated private static func cacheDirectory() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FluidAudio/Models")
    }
}
