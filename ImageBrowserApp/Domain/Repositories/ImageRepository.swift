import Foundation

protocol ImageRepository {
    func fetchImages() async throws -> [ImageItem]
}
