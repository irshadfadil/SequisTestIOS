import Foundation

struct RemoteImageRepository: ImageRepository {
    private let apiClient: any ImageAPIClient

    init(apiClient: any ImageAPIClient) {
        self.apiClient = apiClient
    }

    func fetchImages() async throws -> [ImageItem] {
        try await apiClient.fetchImages().map { dto in
            try dto.toDomain()
        }
    }
}
