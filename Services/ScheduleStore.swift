import Foundation

final class ScheduleStore {
    private let fileName = "schedule.json"

    private var fileURL: URL? {
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return directory.appendingPathComponent(fileName)
    }

    func save(_ items: [ScheduleItem]) throws {
        guard let fileURL else { throw StoreError.documentsDirectoryUnavailable }

        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(items)
        try data.write(to: fileURL, options: .atomic)
    }

    func load() throws -> [ScheduleItem] {
        guard let fileURL else { throw StoreError.documentsDirectoryUnavailable }
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([ScheduleItem].self, from: data)
    }
}
