import Foundation

struct ImageResponseDTO: Decodable, Equatable {
    let id: String
    let author: String
    let width: Int
    let height: Int
    let url: String
    let downloadURL: String

    enum CodingKeys: String, CodingKey {
        case id
        case author
        case width
        case height
        case url
        case downloadURL = "download_url"
    }

    func toDomain() throws -> ImageItem {
        guard
            let sourceURL = URL(string: url),
            let downloadURL = URL(string: downloadURL)
        else {
            throw ImageLoadingError.invalidImageURL
        }

        return ImageItem(
            id: id,
            author: author,
            width: width,
            height: height,
            sourceURL: sourceURL,
            downloadURL: downloadURL
        )
    }
}
