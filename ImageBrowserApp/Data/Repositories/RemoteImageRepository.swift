import Foundation

struct RemoteImageRepository: ImageRepository {
    private let apiClient: any ImageAPIClient

    init(apiClient: any ImageAPIClient) {
        self.apiClient = apiClient
    }

    func fetchImages(page: Int, limit: Int) async throws -> [ImageItem] {
        try await apiClient.fetchImages(page: page, limit: limit).map { dto in
            try dto.toDomain()
        }
    }
}
