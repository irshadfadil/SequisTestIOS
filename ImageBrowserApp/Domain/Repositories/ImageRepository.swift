import Foundation

protocol ImageRepository {
    func fetchImages(page: Int, limit: Int) async throws -> [ImageItem]
}
