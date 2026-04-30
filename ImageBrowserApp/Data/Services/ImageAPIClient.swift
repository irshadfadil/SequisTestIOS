import Foundation

protocol ImageAPIClient {
    func fetchImages(page: Int, limit: Int) async throws -> [ImageResponseDTO]
}

struct LiveImageAPIClient: ImageAPIClient {
    private let session: URLSession
    private let baseEndpoint = URL(string: "https://picsum.photos/v2/list")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchImages(page: Int, limit: Int) async throws -> [ImageResponseDTO] {
        var components = URLComponents(url: baseEndpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit)),
        ]

        guard let endpoint = components?.url else {
            throw ImageLoadingError.invalidResponse
        }

        let (data, response) = try await session.data(from: endpoint)

        guard let httpResponse = response as? HTTPURLResponse, 200 ..< 300 ~= httpResponse.statusCode else {
            throw ImageLoadingError.invalidResponse
        }

        return try JSONDecoder().decode([ImageResponseDTO].self, from: data)
    }
}
