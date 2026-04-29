import Foundation

protocol ImageAPIClient {
    func fetchImages() async throws -> [ImageResponseDTO]
}

struct LiveImageAPIClient: ImageAPIClient {
    private let session: URLSession
    private let endpoint = URL(string: "https://picsum.photos/v2/list")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchImages() async throws -> [ImageResponseDTO] {
        let (data, response) = try await session.data(from: endpoint)

        guard let httpResponse = response as? HTTPURLResponse, 200 ..< 300 ~= httpResponse.statusCode else {
            throw ImageLoadingError.invalidResponse
        }

        return try JSONDecoder().decode([ImageResponseDTO].self, from: data)
    }
}
