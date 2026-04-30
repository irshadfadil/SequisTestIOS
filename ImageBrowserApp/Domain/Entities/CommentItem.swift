import Foundation

struct CommentItem: Identifiable, Equatable {
    let id: UUID
    let imageID: String
    let authorName: String
    let content: String
    let createdAt: Date

    var initials: String {
        let components = authorName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }

        let value = String(components)
        return value.isEmpty ? "?" : value.uppercased()
    }
}
