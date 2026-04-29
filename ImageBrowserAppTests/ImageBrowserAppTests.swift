//
//  ImageBrowserAppTests.swift
//  ImageBrowserAppTests
//
//  Created by Fadil on 30/04/26.
//

import Foundation
import Testing
@testable import ImageBrowserApp

@MainActor
struct ImageBrowserAppTests {

    @Test func imageResponseDTOMapsIntoDomainModel() async throws {
        let dto = ImageResponseDTO(
            id: "42",
            author: "Jane Doe",
            width: 1200,
            height: 800,
            url: "https://example.com/source",
            downloadURL: "https://example.com/download"
        )

        let item = try dto.toDomain()

        #expect(item.id == "42")
        #expect(item.author == "Jane Doe")
        #expect(item.width == 1200)
        #expect(item.height == 800)
        #expect(item.sourceURL.absoluteString == "https://example.com/source")
        #expect(item.downloadURL.absoluteString == "https://example.com/download")
    }

    @Test func repositoryReturnsMappedDomainItems() async throws {
        let client = MockImageAPIClient(result: .success([.fixture(author: "Ada Lovelace")]))
        let repository = RemoteImageRepository(apiClient: client)

        let items = try await repository.fetchImages()

        #expect(client.fetchCallCount == 1)
        #expect(items == [.fixture(author: "Ada Lovelace")])
    }

    @Test func listViewModelLoadsImagesSuccessfully() async throws {
        let repository = MockImageRepository(result: .success([.fixture(author: "Grace Hopper")]))
        let viewModel = ImageListViewModel(
            fetchImagesUseCase: FetchImagesUseCase(repository: repository)
        )

        await viewModel.loadImages()

        #expect(repository.fetchCallCount == 1)
        #expect(viewModel.state == .loaded([.fixture(author: "Grace Hopper")]))
    }

    @Test func listViewModelShowsErrorWhenLoadingFails() async throws {
        let repository = MockImageRepository(result: .failure(MockFailure.sample))
        let viewModel = ImageListViewModel(
            fetchImagesUseCase: FetchImagesUseCase(repository: repository)
        )

        await viewModel.loadImages()

        #expect(repository.fetchCallCount == 1)
        #expect(viewModel.state == .error(ImageListViewModel.defaultErrorMessage))
    }

    @Test func retryTriggersAnotherFetchAfterFailure() async throws {
        let repository = SequencedImageRepository(results: [
            .failure(MockFailure.sample),
            .success([.fixture(author: "Katherine Johnson")]),
        ])
        let viewModel = ImageListViewModel(
            fetchImagesUseCase: FetchImagesUseCase(repository: repository)
        )

        await viewModel.loadImages()
        #expect(viewModel.state == .error(ImageListViewModel.defaultErrorMessage))

        await viewModel.retry()

        #expect(repository.fetchCallCount == 2)
        #expect(viewModel.state == .loaded([.fixture(author: "Katherine Johnson")]))
    }

    @Test func appLaunchViewModelMountsContentBehindSplashAndStartsFetchingImmediately() async throws {
        let repository = MockImageRepository(result: .success([.fixture(author: "Paul Jarvis")]))
        let listViewModel = ImageListViewModel(
            fetchImagesUseCase: FetchImagesUseCase(repository: repository)
        )
        let sleeper = ControlledSleeper()
        let viewModel = AppLaunchViewModel(
            imageListViewModel: listViewModel,
            minimumSplashDuration: .seconds(1),
            sleep: { duration in
                await sleeper.sleep(for: duration)
            }
        )

        let task = Task {
            await viewModel.start()
        }
        await Task.yield()

        #expect(repository.fetchCallCount == 1)
        #expect(viewModel.phase == .contentBehindSplash)

        await sleeper.resume()
        await task.value

        #expect(viewModel.phase == .main)
    }

    @Test func appLaunchViewModelWaitsForMinimumSplashDurationBeforeDismissing() async throws {
        let repository = MockImageRepository(result: .success([.fixture(author: "Grace Hopper")]))
        let listViewModel = ImageListViewModel(
            fetchImagesUseCase: FetchImagesUseCase(repository: repository),
            loadingRevealDelay: .zero
        )
        let splashSleeper = ControlledSleeper()
        let viewModel = AppLaunchViewModel(
            imageListViewModel: listViewModel,
            minimumSplashDuration: .seconds(1),
            sleep: { duration in
                await splashSleeper.sleep(for: duration)
            }
        )

        let task = Task {
            await viewModel.start()
        }
        await Task.yield()

        #expect(viewModel.phase == .contentBehindSplash)

        await Task.yield()
        #expect(viewModel.phase == .contentBehindSplash)

        await splashSleeper.resume()
        await task.value

        #expect(viewModel.phase == .main)
    }

    @Test func appLaunchViewModelWaitsForRevealReadinessAfterMinimumDuration() async throws {
        let repository = SuspendingImageRepository()
        let readinessSleeper = ControlledSleeper()
        let listViewModel = ImageListViewModel(
            fetchImagesUseCase: FetchImagesUseCase(repository: repository),
            loadingRevealDelay: .milliseconds(200),
            sleep: { duration in
                await readinessSleeper.sleep(for: duration)
            }
        )
        let splashSleeper = ControlledSleeper()
        let viewModel = AppLaunchViewModel(
            imageListViewModel: listViewModel,
            minimumSplashDuration: .seconds(1),
            sleep: { duration in
                await splashSleeper.sleep(for: duration)
            }
        )

        let task = Task {
            await viewModel.start()
        }
        await Task.yield()

        #expect(viewModel.phase == .contentBehindSplash)

        await splashSleeper.resume()
        await Task.yield()
        #expect(viewModel.phase == .contentBehindSplash)

        await readinessSleeper.resume()
        await task.value

        #expect(viewModel.phase == .main)

        await repository.resume(with: [.fixture(author: "Loaded Later")])
    }
}

private enum MockFailure: Error {
    case sample
}

@MainActor
private final class MockImageRepository: ImageRepository {
    private let result: Result<[ImageItem], Error>
    private(set) var fetchCallCount = 0

    init(result: Result<[ImageItem], Error>) {
        self.result = result
    }

    func fetchImages() async throws -> [ImageItem] {
        fetchCallCount += 1
        return try result.get()
    }
}

@MainActor
private final class SequencedImageRepository: ImageRepository {
    private var results: [Result<[ImageItem], Error>]
    private(set) var fetchCallCount = 0

    init(results: [Result<[ImageItem], Error>]) {
        self.results = results
    }

    func fetchImages() async throws -> [ImageItem] {
        fetchCallCount += 1
        return try results.removeFirst().get()
    }
}

@MainActor
private final class MockImageAPIClient: ImageAPIClient {
    private let result: Result<[ImageResponseDTO], Error>
    private(set) var fetchCallCount = 0

    init(result: Result<[ImageResponseDTO], Error>) {
        self.result = result
    }

    func fetchImages() async throws -> [ImageResponseDTO] {
        fetchCallCount += 1
        return try result.get()
    }
}

private actor ControlledSleeper {
    private var continuation: CheckedContinuation<Void, Never>?

    func sleep(for _: Duration) async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func resume() {
        continuation?.resume()
        continuation = nil
    }
}

@MainActor
private final class SuspendingImageRepository: ImageRepository {
    private var continuation: CheckedContinuation<[ImageItem], Error>?
    private(set) var fetchCallCount = 0

    func fetchImages() async throws -> [ImageItem] {
        fetchCallCount += 1
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func resume(with items: [ImageItem]) {
        continuation?.resume(returning: items)
        continuation = nil
    }
}

private extension ImageResponseDTO {
    static func fixture(
        id: String = "1",
        author: String = "Author",
        width: Int = 400,
        height: Int = 300,
        url: String = "https://example.com/source",
        downloadURL: String = "https://example.com/download"
    ) -> Self {
        .init(
            id: id,
            author: author,
            width: width,
            height: height,
            url: url,
            downloadURL: downloadURL
        )
    }
}

private extension ImageItem {
    static func fixture(
        id: String = "1",
        author: String = "Author",
        width: Int = 400,
        height: Int = 300,
        sourceURL: URL = URL(string: "https://example.com/source")!,
        downloadURL: URL = URL(string: "https://example.com/download")!
    ) -> Self {
        .init(
            id: id,
            author: author,
            width: width,
            height: height,
            sourceURL: sourceURL,
            downloadURL: downloadURL
        )
    }
}
