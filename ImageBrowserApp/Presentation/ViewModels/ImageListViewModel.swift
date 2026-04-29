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
    static let defaultErrorMessage = "Unable to load images."

    private let fetchImagesUseCase: FetchImagesUseCase
    private(set) var state: ImageListState = .loading

    init(fetchImagesUseCase: FetchImagesUseCase) {
        self.fetchImagesUseCase = fetchImagesUseCase
    }

    func loadImages() async {
        state = .loading

        do {
            let images = try await fetchImagesUseCase.execute()
            state = .loaded(images)
        } catch {
            state = .error(Self.message(for: error))
        }
    }

    func retry() async {
        await loadImages()
    }

    private static func message(for error: Error) -> String {
        if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
            return description
        }

        return defaultErrorMessage
    }
}
