import Foundation

@MainActor
final class InMemoryCommentRepository: CommentRepository {
    private let generator: CommentGenerating
    private let now: () -> Date
    private var commentsByImageID: [String: [CommentItem]] = [:]

    init(
        generator: CommentGenerating,
        now: @escaping () -> Date = Date.init
    ) {
        self.generator = generator
        self.now = now
    }

    func comments(for imageID: String) -> [CommentItem] {
        commentsByImageID[imageID, default: []]
    }

    func addGeneratedComment(for imageID: String) async throws -> CommentItem {
        let comment = try generator.generateComment(for: imageID, createdAt: now())
        commentsByImageID[imageID, default: []].insert(comment, at: 0)
        return comment
    }

    func deleteComment(id: UUID, for imageID: String) {
        commentsByImageID[imageID]?.removeAll { $0.id == id }
    }
}
