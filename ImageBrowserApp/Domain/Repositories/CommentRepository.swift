import Foundation

@MainActor
protocol CommentRepository {
    func comments(for imageID: String) -> [CommentItem]
    func addGeneratedComment(for imageID: String) async throws -> CommentItem
    func deleteComment(id: UUID, for imageID: String)
}
