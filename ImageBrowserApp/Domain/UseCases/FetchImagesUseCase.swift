import Foundation

struct FetchImagesUseCase {
    private let repository: any ImageRepository

    init(repository: any ImageRepository) {
        self.repository = repository
    }

    func execute(page: Int, limit: Int) async throws -> [ImageItem] {
        try await repository.fetchImages(page: page, limit: limit)
    }
}
