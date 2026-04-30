import Foundation

@MainActor
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
            StubImageRepository(mode: .success)
        case "slow-success":
            DelayedImageRepository(
                repository: StubImageRepository(mode: .success),
                delay: .seconds(2)
            )
        case "load-more-failure":
            StubImageRepository(mode: .pageTwoFailure)
        case "load-more-retry-success":
            StubImageRepository(mode: .pageTwoFailsOnce)
        case "failure":
            StubImageRepository(mode: .failure)
        default:
            RemoteImageRepository(apiClient: LiveImageAPIClient())
        }
    }
}

private final class StubImageRepository: ImageRepository {
    enum Mode {
        case success
        case pageTwoFailure
        case pageTwoFailsOnce
        case failure
    }

    let mode: Mode
    private var failedPages = Set<Int>()

    init(mode: Mode) {
        self.mode = mode
    }

    func fetchImages(page: Int, limit: Int) async throws -> [ImageItem] {
        switch mode {
        case .failure:
            throw ImageLoadingError.failedToLoad
        case .pageTwoFailure where page == 2:
            throw ImageLoadingError.failedToLoad
        case .pageTwoFailsOnce where page == 2 && !failedPages.contains(page):
            failedPages.insert(page)
            throw ImageLoadingError.failedToLoad
        case .success, .pageTwoFailure, .pageTwoFailsOnce:
            let startIndex = max((page - 1) * limit, 0)
            guard startIndex < ImageItem.stubItems.count else {
                return []
            }

            let endIndex = min(startIndex + limit, ImageItem.stubItems.count)
            return Array(ImageItem.stubItems[startIndex ..< endIndex])
        }
    }
}

private struct DelayedImageRepository: ImageRepository {
    let repository: any ImageRepository
    let delay: Duration

    func fetchImages(page: Int, limit: Int) async throws -> [ImageItem] {
        try? await Task.sleep(for: delay)
        return try await repository.fetchImages(page: page, limit: limit)
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
    static let stubItems: [ImageItem] = {
        let seeds: [(id: String, author: String)] = [
            ("0", "Alejandro Escamilla"),
            ("1", "Alejandro Escamilla"),
            ("10", "Paul Jarvis"),
            ("100", "Tina Rataj"),
            ("1000", "Lukas Budimaier"),
            ("1001", "Danielle MacInnes"),
            ("1002", "NASA"),
            ("1003", "E+N Photographies"),
            ("1004", "Soo Ann Woon"),
            ("1005", "Mikhail Nilov"),
            ("1006", "Maksim Goncharenok"),
            ("1008", "Khanh Le"),
            ("1009", "Erik Mclean"),
            ("101", "Ales Krivec"),
            ("1010", "Yuli Superson"),
            ("1011", "Luca Bravo"),
            ("1012", "Lina Kivaka"),
            ("1013", "Maddy Baker"),
            ("1014", "Pixabay"),
            ("1015", "Annie Spratt"),
            ("1016", "Artem Labunsky"),
            ("1018", "Taryn Elliott"),
            ("1019", "Vlad Bagacian"),
            ("102", "Daria Shevtsova"),
            ("1020", "Claudio Schwarz"),
            ("1021", "Jake Nackos"),
            ("1022", "Life Of Pix"),
            ("1023", "Jorge Gardner"),
            ("1024", "Matheus Bertelli"),
            ("1025", "Mali Maeder"),
            ("1026", "Simon Berger"),
            ("1027", "Meysam Azarm"),
            ("1028", "Maksim Shutov"),
            ("1029", "Sam Kolder"),
            ("103", "Blaise Darley"),
            ("1031", "Kelly Sikkema"),
            ("1033", "Tom Barrett"),
            ("1035", "Eberhard Grossgasteiger"),
            ("1036", "Matti Blume"),
            ("1037", "Joshua Earle"),
        ]

        return seeds.map { seed in
            .init(
                id: seed.id,
                author: seed.author,
                width: 3200,
                height: 2400,
                sourceURL: URL(string: "https://unsplash.com/photos/\(seed.id)")!,
                downloadURL: URL(string: "https://picsum.photos/id/\(seed.id)/3200/2400")!
            )
        }
    }()
}
