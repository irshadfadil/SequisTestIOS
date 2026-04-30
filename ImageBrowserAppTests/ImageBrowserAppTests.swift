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

    @Test func repositoryReturnsMappedDomainItemsForRequestedPage() async throws {
        let client = MockImageAPIClient(result: .success([.fixture(author: "Ada Lovelace")]))
        let repository = RemoteImageRepository(apiClient: client)

        let items = try await repository.fetchImages(page: 3, limit: 20)

        #expect(client.requests == [.init(page: 3, limit: 20)])
        #expect(items == [.fixture(author: "Ada Lovelace")])
    }

    @Test func listViewModelLoadsFirstPageSuccessfully() async throws {
        let repository = ScriptedImageRepository { page, limit in
            #expect(page == 1)
            #expect(limit == 20)
            return [
                .fixture(id: "1", author: "Grace Hopper"),
                .fixture(id: "2", author: "Katherine Johnson"),
            ]
        }
        let viewModel = ImageListViewModel(
            fetchImagesUseCase: FetchImagesUseCase(repository: repository)
        )

        await viewModel.loadImages()

        #expect(repository.requests == [.init(page: 1, limit: 20)])
        #expect(viewModel.state == .loaded(
            ImageFeedState(
                items: [
                    .fixture(id: "1", author: "Grace Hopper"),
                    .fixture(id: "2", author: "Katherine Johnson"),
                ],
                isLoadingMore: false,
                loadMoreError: nil,
                hasReachedEnd: true
            )
        ))
    }

    @Test func reachingTheEndLoadsTheNextPageOnce() async throws {
        let repository = ScriptedImageRepository { page, _ in
            switch page {
            case 1:
                return (1 ... 20).map { index in
                    .fixture(id: "\(index)", author: "Author \(index)")
                }
            case 2:
                return [
                    .fixture(id: "21", author: "Next Page Author"),
                ]
            default:
                return []
            }
        }
        let viewModel = ImageListViewModel(
            fetchImagesUseCase: FetchImagesUseCase(repository: repository)
        )

        await viewModel.loadImages()
        await viewModel.loadMoreIfNeeded(currentItemID: "17")
        await viewModel.loadMoreIfNeeded(currentItemID: "20")

        #expect(repository.requests == [
            .init(page: 1, limit: 20),
            .init(page: 2, limit: 20),
        ])

        switch viewModel.state {
        case let .loaded(feed):
            #expect(feed.items.count == 21)
            #expect(feed.items.last?.author == "Next Page Author")
            #expect(feed.isLoadingMore == false)
            #expect(feed.loadMoreError == nil)
            #expect(feed.hasReachedEnd == true)
        default:
            #expect(Bool(false))
        }
    }

    @Test func loadMoreFailureKeepsExistingItemsAndShowsFooterError() async throws {
        let repository = SequencedPageRepository(responsesByPage: [
            1: [
                .success((1 ... 20).map { index in
                    .fixture(id: "\(index)", author: "Author \(index)")
                }),
            ],
            2: [
                .failure(MockFailure.sample),
            ],
        ])
        let viewModel = ImageListViewModel(
            fetchImagesUseCase: FetchImagesUseCase(repository: repository)
        )

        await viewModel.loadImages()
        await viewModel.loadMoreIfNeeded(currentItemID: "20")

        #expect(repository.requests == [
            .init(page: 1, limit: 20),
            .init(page: 2, limit: 20),
        ])

        switch viewModel.state {
        case let .loaded(feed):
            #expect(feed.items.count == 20)
            #expect(feed.isLoadingMore == false)
            #expect(feed.loadMoreError == ImageListViewModel.defaultErrorMessage)
            #expect(feed.hasReachedEnd == false)
        default:
            #expect(Bool(false))
        }
    }

    @Test func retryLoadMoreRequestsTheFailedPageAgainAndAppendsResults() async throws {
        let repository = SequencedPageRepository(responsesByPage: [
            1: [
                .success((1 ... 20).map { index in
                    .fixture(id: "\(index)", author: "Author \(index)")
                }),
            ],
            2: [
                .failure(MockFailure.sample),
                .success([
                    .fixture(id: "21", author: "Retry Success"),
                    .fixture(id: "22", author: "Retry Success 2"),
                ]),
            ],
        ])
        let viewModel = ImageListViewModel(
            fetchImagesUseCase: FetchImagesUseCase(repository: repository)
        )

        await viewModel.loadImages()
        await viewModel.loadMoreIfNeeded(currentItemID: "20")
        await viewModel.retryLoadMore()

        #expect(repository.requests == [
            .init(page: 1, limit: 20),
            .init(page: 2, limit: 20),
            .init(page: 2, limit: 20),
        ])

        switch viewModel.state {
        case let .loaded(feed):
            #expect(feed.items.count == 22)
            #expect(feed.items.suffix(2).map(\.author) == ["Retry Success", "Retry Success 2"])
            #expect(feed.loadMoreError == nil)
            #expect(feed.hasReachedEnd == true)
        default:
            #expect(Bool(false))
        }
    }

    @Test func duplicateIdsAcrossPagesAreOnlyStoredOnce() async throws {
        let repository = SequencedPageRepository(responsesByPage: [
            1: [
                .success([
                    .fixture(id: "1", author: "Author 1"),
                    .fixture(id: "2", author: "Author 2"),
                ]),
            ],
            2: [
                .success([
                    .fixture(id: "2", author: "Author 2 Duplicate"),
                    .fixture(id: "3", author: "Author 3"),
                ]),
            ],
        ])
        let viewModel = ImageListViewModel(
            fetchImagesUseCase: FetchImagesUseCase(repository: repository),
            pageSize: 2
        )

        await viewModel.loadImages()
        await viewModel.loadMoreIfNeeded(currentItemID: "2")

        switch viewModel.state {
        case let .loaded(feed):
            #expect(feed.items.map(\.id) == ["1", "2", "3"])
            #expect(feed.items.count == 3)
        default:
            #expect(Bool(false))
        }
    }

    @Test func shortPageMarksTheEndAndPreventsFurtherRequests() async throws {
        let repository = SequencedPageRepository(responsesByPage: [
            1: [
                .success((1 ... 20).map { index in
                    .fixture(id: "\(index)", author: "Author \(index)")
                }),
            ],
            2: [
                .success([
                    .fixture(id: "21", author: "Last Page Author"),
                ]),
            ],
        ])
        let viewModel = ImageListViewModel(
            fetchImagesUseCase: FetchImagesUseCase(repository: repository)
        )

        await viewModel.loadImages()
        await viewModel.loadMoreIfNeeded(currentItemID: "20")
        await viewModel.loadMoreIfNeeded(currentItemID: "21")

        #expect(repository.requests == [
            .init(page: 1, limit: 20),
            .init(page: 2, limit: 20),
        ])

        switch viewModel.state {
        case let .loaded(feed):
            #expect(feed.hasReachedEnd == true)
            #expect(feed.items.count == 21)
        default:
            #expect(Bool(false))
        }
    }

    @Test func commentResourcesDecodeIntoNonEmptyWordLists() throws {
        let loader = JSONFileWordListLoader(resourceDirectoryURL: resourceDirectoryURL)

        let wordLists = try loader.loadWordLists()

        #expect(!wordLists.firstNames.isEmpty)
        #expect(!wordLists.lastNames.isEmpty)
        #expect(!wordLists.verbs.isEmpty)
        #expect(!wordLists.nouns.isEmpty)
    }

    @Test func randomCommentGeneratorCreatesANameAndContent() throws {
        let generator = RandomCommentGenerator(
            loader: StubWordListLoader(
                wordLists: .init(
                    firstNames: ["Tim"],
                    lastNames: ["Mills"],
                    verbs: ["work", "reply"],
                    nouns: ["field", "month"]
                )
            )
        )

        let comment = try generator.generateComment(
            for: "1002",
            createdAt: Date(timeIntervalSince1970: 100)
        )

        #expect(comment.imageID == "1002")
        #expect(comment.authorName.split(separator: " ").count == 2)
        #expect(!comment.content.isEmpty)
    }

    @Test func detailViewModelStartsEmptyForANewImage() {
        let repository = TestCommentRepository()
        let viewModel = ImageDetailViewModel(
            image: .fixture(id: "detail-1"),
            commentRepository: repository
        )

        viewModel.loadComments()

        #expect(viewModel.comments.isEmpty)
    }

    @Test func addCommentInsertsTheNewestCommentAtTheTop() async {
        let repository = TestCommentRepository()
        let viewModel = ImageDetailViewModel(
            image: .fixture(id: "detail-1"),
            commentRepository: repository,
            now: { Date(timeIntervalSince1970: 10_000) }
        )

        await viewModel.addComment()
        await viewModel.addComment()

        #expect(viewModel.comments.count == 2)
        #expect(viewModel.comments[0].createdAt >= viewModel.comments[1].createdAt)
    }

    @Test func deleteCommentRemovesTheTargetComment() async throws {
        let repository = TestCommentRepository()
        let viewModel = ImageDetailViewModel(
            image: .fixture(id: "detail-2"),
            commentRepository: repository
        )

        await viewModel.addComment()
        await viewModel.addComment()

        let removedID = try #require(viewModel.comments.last?.id)
        viewModel.deleteComment(id: removedID)

        #expect(viewModel.comments.count == 1)
        #expect(viewModel.comments.contains(where: { $0.id == removedID }) == false)
    }

    @Test func commentsRemainIsolatedPerImageID() async {
        let repository = TestCommentRepository()
        let firstViewModel = ImageDetailViewModel(
            image: .fixture(id: "image-a"),
            commentRepository: repository
        )
        let secondViewModel = ImageDetailViewModel(
            image: .fixture(id: "image-b"),
            commentRepository: repository
        )

        await firstViewModel.addComment()
        secondViewModel.loadComments()

        #expect(firstViewModel.comments.count == 1)
        #expect(secondViewModel.comments.isEmpty)
    }

    @Test func newCommentsShowNowAsTheRelativeDate() async throws {
        let fixedNow = Date(timeIntervalSince1970: 5_000)
        let repository = TestCommentRepository(now: { fixedNow })
        let viewModel = ImageDetailViewModel(
            image: .fixture(id: "detail-3"),
            commentRepository: repository,
            now: { fixedNow }
        )

        await viewModel.addComment()
        let newestComment = try #require(viewModel.comments.first)

        #expect(viewModel.relativeDateText(for: newestComment) == "now")
    }

    @Test func generatorFailureDoesNotCrashDetailState() async {
        let repository = FailingCommentRepository(error: CommentGenerationError.missingResource("verbs"))
        let viewModel = ImageDetailViewModel(
            image: .fixture(id: "detail-4"),
            commentRepository: repository
        )

        await viewModel.addComment()

        #expect(viewModel.comments.isEmpty)
        #expect(viewModel.errorMessage == "Missing comment resource: verbs.")
    }

    @Test func appLaunchViewModelMountsContentBehindSplashAndStartsFetchingImmediately() async throws {
        let repository = ScriptedImageRepository { _, _ in
            [.fixture(author: "Paul Jarvis")]
        }
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

        #expect(repository.requests == [.init(page: 1, limit: 20)])
        #expect(viewModel.phase == .contentBehindSplash)

        await sleeper.resume()
        await task.value

        #expect(viewModel.phase == .main)
    }

    @Test func appLaunchViewModelWaitsForMinimumSplashDurationBeforeDismissing() async throws {
        let repository = ScriptedImageRepository { _, _ in
            [.fixture(author: "Grace Hopper")]
        }
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

private struct PageRequest: Equatable {
    let page: Int
    let limit: Int
}

@MainActor
private final class ScriptedImageRepository: ImageRepository {
    private let handler: @MainActor (Int, Int) async throws -> [ImageItem]
    private(set) var requests: [PageRequest] = []

    init(handler: @escaping @MainActor (Int, Int) async throws -> [ImageItem]) {
        self.handler = handler
    }

    func fetchImages(page: Int, limit: Int) async throws -> [ImageItem] {
        requests.append(.init(page: page, limit: limit))
        return try await handler(page, limit)
    }
}

@MainActor
private final class SequencedPageRepository: ImageRepository {
    private var responsesByPage: [Int: [Result<[ImageItem], Error>]]
    private(set) var requests: [PageRequest] = []

    init(responsesByPage: [Int: [Result<[ImageItem], Error>]]) {
        self.responsesByPage = responsesByPage
    }

    func fetchImages(page: Int, limit: Int) async throws -> [ImageItem] {
        requests.append(.init(page: page, limit: limit))

        guard var responses = responsesByPage[page], !responses.isEmpty else {
            return []
        }

        let result = responses.removeFirst()
        responsesByPage[page] = responses
        return try result.get()
    }
}

@MainActor
private final class MockImageAPIClient: ImageAPIClient {
    private let result: Result<[ImageResponseDTO], Error>
    private(set) var requests: [PageRequest] = []

    init(result: Result<[ImageResponseDTO], Error>) {
        self.result = result
    }

    func fetchImages(page: Int, limit: Int) async throws -> [ImageResponseDTO] {
        requests.append(.init(page: page, limit: limit))
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
    private(set) var requests: [PageRequest] = []

    func fetchImages(page: Int, limit: Int) async throws -> [ImageItem] {
        requests.append(.init(page: page, limit: limit))
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

private extension ImageBrowserAppTests {
    var resourceDirectoryURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ImageBrowserApp")
            .appendingPathComponent("resources")
    }
}

private struct StubWordListLoader: CommentWordListLoading {
    let wordLists: CommentWordLists

    func loadWordLists() throws -> CommentWordLists {
        wordLists
    }
}

@MainActor
private final class TestCommentRepository: CommentRepository {
    private let repository: InMemoryCommentRepository

    init(
        generator: CommentGenerating = TestCommentGenerator(),
        now: @escaping () -> Date = Date.init
    ) {
        repository = InMemoryCommentRepository(generator: generator, now: now)
    }

    func comments(for imageID: String) -> [CommentItem] {
        repository.comments(for: imageID)
    }

    func addGeneratedComment(for imageID: String) async throws -> CommentItem {
        try await repository.addGeneratedComment(for: imageID)
    }

    func deleteComment(id: UUID, for imageID: String) {
        repository.deleteComment(id: id, for: imageID)
    }
}

@MainActor
private struct TestCommentGenerator: CommentGenerating {
    private var names = ["Tim Vn Zandt", "Roger Root", "Carl Kassing"]
    private var messages = [
        "work jellyfish tool last art party repeat care robin foot army snow mend amuse unlock camp nose stop stomach month reply ocean girl tour rule",
        "lock plastic insect base strap money boil shoe object sort wave look part road scorch moan stir vessel cloth night beds melt flower",
        "level fly tame ladybug ban surprise thing punish grass store press boat queen reduce grandmother turkey quartz thaw unlock vest dock request switch crowd cows recognise yawn moor plan",
    ]
    private static var nextIndex = 0

    func generateComment(for imageID: String, createdAt: Date) throws -> CommentItem {
        let index = Self.nextIndex
        Self.nextIndex += 1
        let name = names[index % names.count]
        let content = messages[index % messages.count]

        return CommentItem(
            id: UUID(),
            imageID: imageID,
            authorName: name,
            content: content,
            createdAt: createdAt
        )
    }
}

@MainActor
private final class FailingCommentRepository: CommentRepository {
    let error: Error

    init(error: Error) {
        self.error = error
    }

    func comments(for imageID _: String) -> [CommentItem] {
        []
    }

    func addGeneratedComment(for imageID _: String) async throws -> CommentItem {
        throw error
    }

    func deleteComment(id _: UUID, for imageID _: String) {}
}
