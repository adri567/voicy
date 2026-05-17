import CoreML
import Foundation
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

    init() {}

    func loadModel() async throws {
        guard diarizer == nil else { return }
        guard isModelInstalled() else {
            print("[LS-EEND] Skipping auto-load — model not on disk")
            return
        }
        print("[LS-EEND] Loading from cache (\(Self.activeVariant), \(Self.activeStepSize))…")
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
        print("[LS-EEND] Model ready")
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

    func installModel(progress: @escaping @Sendable (Double) -> Void) async throws {
        if isModelInstalled(), diarizer != nil {
            progress(1.0)
            return
        }
        print("[LS-EEND] Install start — fetching from HuggingFace…")
        do {
            let model = try await LSEENDModel.loadFromHuggingFace(
                variant: Self.activeVariant,
                stepSize: Self.activeStepSize,
                cacheDirectory: nil,
                computeUnits: .cpuOnly,
                progressHandler: { p in
                    print("[LS-EEND] progress \(String(format: "%.0f%% (%@)", p.fractionCompleted * 100, String(describing: p.phase)))")
                    progress(p.fractionCompleted)
                }
            )
            print("[LS-EEND] Download finished, initializing diarizer…")
            let d = LSEENDDiarizer(timelineConfig: nil)
            try d.initialize(model: model)
            diarizer = d
            progress(1.0)
            print("[LS-EEND] Model installed")
        } catch {
            print("[LS-EEND] Install failed: \(error)")
            throw error
        }
    }

    func removeModel() async throws {
        diarizer = nil
        try Self.remove(variant: Self.activeVariant)
        print("[LS-EEND] Model removed from disk")
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
