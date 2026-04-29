import Foundation

struct FetchImagesUseCase {
    private let repository: any ImageRepository

    init(repository: any ImageRepository) {
        self.repository = repository
    }

    func execute() async throws -> [ImageItem] {
        try await repository.fetchImages()
    }
}
