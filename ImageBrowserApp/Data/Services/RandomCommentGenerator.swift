import Foundation

struct CommentWordLists: Equatable {
    let firstNames: [String]
    let lastNames: [String]
    let verbs: [String]
    let nouns: [String]
}

protocol CommentWordListLoading {
    func loadWordLists() throws -> CommentWordLists
}

@MainActor
protocol CommentGenerating {
    func generateComment(for imageID: String, createdAt: Date) throws -> CommentItem
}

struct JSONFileWordListLoader: CommentWordListLoading {
    private let resourceDirectoryURL: URL?
    private let bundle: Bundle?
    private let subdirectory: String?
    private let decoder = JSONDecoder()

    init(resourceDirectoryURL: URL) {
        self.resourceDirectoryURL = resourceDirectoryURL
        bundle = nil
        subdirectory = nil
    }

    init(bundle: Bundle, subdirectory: String? = nil) {
        resourceDirectoryURL = nil
        self.bundle = bundle
        self.subdirectory = subdirectory
    }

    func loadWordLists() throws -> CommentWordLists {
        try .init(
            firstNames: loadWords(named: "firstNames"),
            lastNames: loadWords(named: "lastNames"),
            verbs: loadWords(named: "verbs"),
            nouns: loadWords(named: "nouns")
        )
    }

    private func loadWords(named name: String) throws -> [String] {
        guard let fileURL = fileURL(named: name) else {
            throw CommentGenerationError.missingResource(name)
        }

        let data = try Data(contentsOf: fileURL)
        let words: [String]

        do {
            words = try decoder.decode([String].self, from: data)
        } catch {
            throw CommentGenerationError.invalidResource(name)
        }

        guard !words.isEmpty else {
            throw CommentGenerationError.emptyResource(name)
        }

        return words
    }

    private func fileURL(named name: String) -> URL? {
        if let bundle {
            if let bundledURL = bundle.url(forResource: name, withExtension: "json", subdirectory: subdirectory) {
                return bundledURL
            }

            return bundle.url(forResource: name, withExtension: "json")
        }

        guard let resourceDirectoryURL else {
            return nil
        }

        return resourceDirectoryURL.appending(path: "\(name).json")
    }
}

@MainActor
final class RandomCommentGenerator: CommentGenerating {
    private let loader: CommentWordListLoading
    private var cachedWordLists: CommentWordLists?

    init(loader: CommentWordListLoading) {
        self.loader = loader
    }

    func generateComment(for imageID: String, createdAt: Date) throws -> CommentItem {
        let wordLists = try cachedWordLists ?? loadAndCacheWordLists()

        let firstName = try randomElement(from: wordLists.firstNames, resourceName: "firstNames")
        let lastName = try randomElement(from: wordLists.lastNames, resourceName: "lastNames")
        let content = try makeSentence(wordLists: wordLists)

        return CommentItem(
            id: UUID(),
            imageID: imageID,
            authorName: "\(firstName) \(lastName)",
            content: content,
            createdAt: createdAt
        )
    }

    private func loadAndCacheWordLists() throws -> CommentWordLists {
        let wordLists = try loader.loadWordLists()
        cachedWordLists = wordLists
        return wordLists
    }

    private func makeSentence(wordLists: CommentWordLists) throws -> String {
        let wordCount = Int.random(in: 14 ... 20)
        let words = try (0 ..< wordCount).map { index in
            switch index % 3 {
            case 0:
                try randomElement(from: wordLists.verbs, resourceName: "verbs")
            case 1:
                try randomElement(from: wordLists.nouns, resourceName: "nouns")
            default:
                Bool.random()
                    ? try randomElement(from: wordLists.verbs, resourceName: "verbs")
                    : try randomElement(from: wordLists.nouns, resourceName: "nouns")
            }
        }

        return words.joined(separator: " ")
    }

    private func randomElement(from values: [String], resourceName: String) throws -> String {
        guard let value = values.randomElement() else {
            throw CommentGenerationError.emptyResource(resourceName)
        }

        return value
    }
}

enum CommentGenerationError: LocalizedError, Equatable {
    case missingResource(String)
    case emptyResource(String)
    case invalidResource(String)

    var errorDescription: String? {
        switch self {
        case let .missingResource(name):
            "Missing comment resource: \(name)."
        case let .emptyResource(name):
            "Comment resource \(name) is empty."
        case let .invalidResource(name):
            "Comment resource \(name) could not be decoded."
        }
    }
}
