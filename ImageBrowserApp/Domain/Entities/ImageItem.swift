import Foundation

struct ImageItem: Identifiable, Equatable {
    let id: String
    let author: String
    let width: Int
    let height: Int
    let sourceURL: URL
    let downloadURL: URL

    var thumbnailURL: URL {
        URL(string: "https://picsum.photos/id/\(id)/320/320") ?? downloadURL
    }

    var detailImageURL: URL {
        URL(string: "https://picsum.photos/id/\(id)/1200/900") ?? downloadURL
    }
}
