import Foundation
import Observation

@Observable
@MainActor
final class ImageDetailViewModel {
    let image: ImageItem

    private let commentRepository: CommentRepository
    private let relativeDateFormatter: RelativeDateTimeFormatter
    private let now: () -> Date

    private(set) var comments: [CommentItem] = []
    var errorMessage: String?

    init(
        image: ImageItem,
        commentRepository: CommentRepository,
        now: @escaping () -> Date = Date.init
    ) {
        self.image = image
        self.commentRepository = commentRepository
        self.now = now

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named
        relativeDateFormatter = formatter
    }

    func loadComments() {
        comments = commentRepository.comments(for: image.id)
    }

    func addComment() async {
        do {
            _ = try await commentRepository.addGeneratedComment(for: image.id)
            errorMessage = nil
            loadComments()
        } catch {
            errorMessage = message(for: error)
        }
    }

    func deleteComment(id: UUID) {
        commentRepository.deleteComment(id: id, for: image.id)
        loadComments()
    }

    func relativeDateText(for comment: CommentItem) -> String {
        let referenceDate = now()

        if abs(comment.createdAt.timeIntervalSince(referenceDate)) < 60 {
            return "now"
        }

        return relativeDateFormatter.localizedString(for: comment.createdAt, relativeTo: referenceDate)
    }

    private func message(for error: Error) -> String {
        if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
            return description
        }

        return "Unable to add comment."
    }
}
