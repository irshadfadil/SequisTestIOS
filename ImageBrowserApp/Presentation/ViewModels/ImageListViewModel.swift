import Foundation
import Observation

enum ImageListState: Equatable {
    case loading
    case loaded([ImageItem])
    case error(String)
}

@Observable
@MainActor
final class ImageListViewModel {
    typealias SleepHandler = @Sendable (Duration) async -> Void

    static let defaultErrorMessage = "Unable to load images."

    private let fetchImagesUseCase: FetchImagesUseCase
    private let loadingRevealDelay: Duration
    private let sleep: SleepHandler
    private var readinessTask: Task<Void, Never>?
    private var readyContinuation: CheckedContinuation<Void, Never>?

    private(set) var state: ImageListState = .loading
    private(set) var isReadyForReveal = false

    init(
        fetchImagesUseCase: FetchImagesUseCase,
        loadingRevealDelay: Duration = .milliseconds(250),
        sleep: @escaping SleepHandler = { duration in
            try? await Task.sleep(for: duration)
        }
    ) {
        self.fetchImagesUseCase = fetchImagesUseCase
        self.loadingRevealDelay = loadingRevealDelay
        self.sleep = sleep
    }

    func loadImages() async {
        readinessTask?.cancel()
        isReadyForReveal = false
        state = .loading
        scheduleLoadingRevealReadiness()

        do {
            let images = try await fetchImagesUseCase.execute()
            readinessTask?.cancel()
            state = .loaded(images)
            markReadyForReveal()
        } catch {
            readinessTask?.cancel()
            state = .error(Self.message(for: error))
            markReadyForReveal()
        }
    }

    func retry() async {
        await loadImages()
    }

    func waitUntilReadyForReveal() async {
        guard !isReadyForReveal else { return }

        await withCheckedContinuation { continuation in
            if isReadyForReveal {
                continuation.resume()
            } else {
                readyContinuation = continuation
            }
        }
    }

    private static func message(for error: Error) -> String {
        if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
            return description
        }

        return defaultErrorMessage
    }

    private func scheduleLoadingRevealReadiness() {
        readinessTask = Task { [loadingRevealDelay, sleep] in
            if loadingRevealDelay > .zero {
                await sleep(loadingRevealDelay)
            }

            guard !Task.isCancelled else { return }
            await markReadyForRevealIfStillLoading()
        }
    }

    private func markReadyForRevealIfStillLoading() {
        guard state == .loading else { return }
        markReadyForReveal()
    }

    private func markReadyForReveal() {
        guard !isReadyForReveal else { return }
        isReadyForReveal = true
        readyContinuation?.resume()
        readyContinuation = nil
    }
}
