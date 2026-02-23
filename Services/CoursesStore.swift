import Foundation

enum StoreError: LocalizedError {
    case documentsDirectoryUnavailable

    var errorDescription: String? {
        switch self {
        case .documentsDirectoryUnavailable:
            return "Documents directory is unavailable."
        }
    }
}

final class CoursesStore {
    private let fileName = "subjects.json"

    private var fileURL: URL? {
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return directory.appendingPathComponent(fileName)
    }

    func save(_ subjects: [Subject]) throws {
        guard let fileURL else { throw StoreError.documentsDirectoryUnavailable }

        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(subjects)
        try data.write(to: fileURL, options: .atomic)
    }

    func load() throws -> [Subject] {
        guard let fileURL else { throw StoreError.documentsDirectoryUnavailable }
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([Subject].self, from: data)
    }
}
