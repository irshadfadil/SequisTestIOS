import Foundation
import Observation

struct ImageFeedState: Equatable {
    var items: [ImageItem]
    var isLoadingMore: Bool
    var loadMoreError: String?
    var hasReachedEnd: Bool
}

enum ImageListState: Equatable {
    case initialLoading
    case loaded(ImageFeedState)
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
    private let pageSize: Int
    private let prefetchThreshold: Int
    private var readinessTask: Task<Void, Never>?
    private var readyContinuation: CheckedContinuation<Void, Never>?
    private var currentPage = 1
    private var isRequestInFlight = false

    private(set) var state: ImageListState = .initialLoading
    private(set) var isReadyForReveal = false

    init(
        fetchImagesUseCase: FetchImagesUseCase,
        pageSize: Int = 20,
        prefetchThreshold: Int = 4,
        loadingRevealDelay: Duration = .milliseconds(250),
        sleep: @escaping SleepHandler = { duration in
            try? await Task.sleep(for: duration)
        }
    ) {
        self.fetchImagesUseCase = fetchImagesUseCase
        self.pageSize = pageSize
        self.prefetchThreshold = prefetchThreshold
        self.loadingRevealDelay = loadingRevealDelay
        self.sleep = sleep
    }

    func loadImages() async {
        readinessTask?.cancel()
        isReadyForReveal = false
        currentPage = 1
        isRequestInFlight = true
        state = .initialLoading
        scheduleLoadingRevealReadiness()

        do {
            let images = try await fetchImagesUseCase.execute(page: currentPage, limit: pageSize)
            readinessTask?.cancel()

            state = .loaded(
                ImageFeedState(
                    items: deduplicatedItems(from: images),
                    isLoadingMore: false,
                    loadMoreError: nil,
                    hasReachedEnd: images.count < pageSize
                )
            )
            currentPage += 1
            markReadyForReveal()
        } catch {
            readinessTask?.cancel()
            state = .error(Self.message(for: error))
            markReadyForReveal()
        }

        isRequestInFlight = false
    }

    func retry() async {
        await loadImages()
    }

    func loadMoreIfNeeded(currentItemID: String) async {
        guard case let .loaded(feed) = state else { return }
        guard !isRequestInFlight, !feed.isLoadingMore, feed.loadMoreError == nil, !feed.hasReachedEnd else {
            return
        }
        guard shouldPrefetch(for: currentItemID, in: feed.items) else { return }

        await loadMore()
    }

    func retryLoadMore() async {
        guard case let .loaded(feed) = state, feed.loadMoreError != nil else { return }
        await loadMore()
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

    private func loadMore() async {
        guard case let .loaded(feed) = state, !isRequestInFlight else { return }

        isRequestInFlight = true
        state = .loaded(
            ImageFeedState(
                items: feed.items,
                isLoadingMore: true,
                loadMoreError: nil,
                hasReachedEnd: feed.hasReachedEnd
            )
        )

        do {
            let nextPageItems = try await fetchImagesUseCase.execute(page: currentPage, limit: pageSize)
            let mergedItems = mergedItems(existing: feed.items, incoming: nextPageItems)

            state = .loaded(
                ImageFeedState(
                    items: mergedItems,
                    isLoadingMore: false,
                    loadMoreError: nil,
                    hasReachedEnd: nextPageItems.count < pageSize
                )
            )
            currentPage += 1
        } catch {
            state = .loaded(
                ImageFeedState(
                    items: feed.items,
                    isLoadingMore: false,
                    loadMoreError: Self.message(for: error),
                    hasReachedEnd: feed.hasReachedEnd
                )
            )
        }

        isRequestInFlight = false
    }

    private func shouldPrefetch(for currentItemID: String, in items: [ImageItem]) -> Bool {
        guard let currentIndex = items.firstIndex(where: { $0.id == currentItemID }) else {
            return false
        }

        let thresholdIndex = max(items.count - min(prefetchThreshold, items.count), 0)
        return currentIndex >= thresholdIndex
    }

    private func deduplicatedItems(from items: [ImageItem]) -> [ImageItem] {
        mergedItems(existing: [], incoming: items)
    }

    private func mergedItems(existing: [ImageItem], incoming: [ImageItem]) -> [ImageItem] {
        var seenIDs = Set(existing.map(\.id))
        var mergedItems = existing

        for item in incoming where seenIDs.insert(item.id).inserted {
            mergedItems.append(item)
        }

        return mergedItems
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
        guard state == .initialLoading else { return }
        markReadyForReveal()
    }

    private func markReadyForReveal() {
        guard !isReadyForReveal else { return }
        isReadyForReveal = true
        readyContinuation?.resume()
        readyContinuation = nil
    }
}
