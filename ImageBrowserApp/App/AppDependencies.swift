import Foundation

enum AppDependencies {
    static func makeLaunchViewModel(processInfo: ProcessInfo = .processInfo) -> AppLaunchViewModel {
        let repository = makeRepository(processInfo: processInfo)
        let listViewModel = ImageListViewModel(
            fetchImagesUseCase: FetchImagesUseCase(repository: repository)
        )

        return AppLaunchViewModel(
            imageListViewModel: listViewModel,
            minimumSplashDuration: .seconds(1.4),
            sleep: { duration in
                try? await Task.sleep(for: duration)
            }
        )
    }

    static func makeRepository(processInfo: ProcessInfo = .processInfo) -> any ImageRepository {
        switch processInfo.environment["IMAGE_BROWSER_STUB_MODE"] {
        case "success":
            StubImageRepository(result: .success(ImageItem.stubItems))
        case "slow-success":
            DelayedImageRepository(
                repository: StubImageRepository(result: .success(ImageItem.stubItems)),
                delay: .seconds(2)
            )
        case "failure":
            StubImageRepository(result: .failure(ImageLoadingError.failedToLoad))
        default:
            RemoteImageRepository(apiClient: LiveImageAPIClient())
        }
    }
}

private struct StubImageRepository: ImageRepository {
    let result: Result<[ImageItem], Error>

    func fetchImages() async throws -> [ImageItem] {
        try result.get()
    }
}

private struct DelayedImageRepository: ImageRepository {
    let repository: any ImageRepository
    let delay: Duration

    func fetchImages() async throws -> [ImageItem] {
        try? await Task.sleep(for: delay)
        return try await repository.fetchImages()
    }
}

enum ImageLoadingError: LocalizedError {
    case failedToLoad
    case invalidResponse
    case invalidImageURL

    var errorDescription: String? {
        switch self {
        case .failedToLoad:
            "Unable to load images."
        case .invalidResponse:
            "The server response was invalid."
        case .invalidImageURL:
            "One of the image URLs was invalid."
        }
    }
}

extension ImageItem {
    static let stubItems: [ImageItem] = [
        .init(
            id: "0",
            author: "Alejandro Escamilla",
            width: 5616,
            height: 3744,
            sourceURL: URL(string: "https://unsplash.com/photos/yC-Yzbqy7PY")!,
            downloadURL: URL(string: "https://picsum.photos/id/0/5616/3744")!
        ),
        .init(
            id: "1",
            author: "Alejandro Escamilla",
            width: 5616,
            height: 3744,
            sourceURL: URL(string: "https://unsplash.com/photos/LNRyGwIJr5c")!,
            downloadURL: URL(string: "https://picsum.photos/id/1/5616/3744")!
        ),
        .init(
            id: "10",
            author: "Paul Jarvis",
            width: 2500,
            height: 1667,
            sourceURL: URL(string: "https://unsplash.com/photos/6J--NXulQCs")!,
            downloadURL: URL(string: "https://picsum.photos/id/10/2500/1667")!
        ),
        .init(
            id: "100",
            author: "Tina Rataj",
            width: 2500,
            height: 1656,
            sourceURL: URL(string: "https://unsplash.com/photos/pwaaqfoMibI")!,
            downloadURL: URL(string: "https://picsum.photos/id/100/2500/1656")!
        ),
        .init(
            id: "1000",
            author: "Lukas Budimaier",
            width: 5626,
            height: 3635,
            sourceURL: URL(string: "https://unsplash.com/photos/6cY-FvMlmkQ")!,
            downloadURL: URL(string: "https://picsum.photos/id/1000/5626/3635")!
        ),
        .init(
            id: "1001",
            author: "Danielle MacInnes",
            width: 5616,
            height: 3744,
            sourceURL: URL(string: "https://unsplash.com/photos/2JddPq7DA00")!,
            downloadURL: URL(string: "https://picsum.photos/id/1001/5616/3744")!
        ),
        .init(
            id: "1002",
            author: "NASA",
            width: 4312,
            height: 2868,
            sourceURL: URL(string: "https://unsplash.com/photos/-hI5dX2ObAs")!,
            downloadURL: URL(string: "https://picsum.photos/id/1002/4312/2868")!
        ),
    ]
}
