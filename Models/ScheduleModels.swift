//
//  File.swift
//  AttendiFy
//
//  Created by Akshit Goyal on 20/02/26.
//

import Foundation

enum Weekday: String, CaseIterable, Codable, Identifiable {
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var shortName: String {
        switch self {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }
}

struct ScheduleItem: Identifiable, Codable, Equatable {

    var id: UUID = UUID()
    var subjectID: UUID
    var day: Weekday
    var startTime: Date
    var endTime: Date
    var lecture: String
    var building: String?
    var lecturesCount: Int

    init(
        id: UUID = UUID(),
        subjectID: UUID,
        day: Weekday,
        startTime: Date,
        endTime: Date,
        lecture: String,
        building: String? = nil,
        lecturesCount: Int = 1
    ) {
        self.id = id
        self.subjectID = subjectID
        self.day = day
        self.startTime = startTime
        self.endTime = endTime
        self.lecture = lecture.trimmingCharacters(in: .whitespacesAndNewlines)
        self.lecturesCount = max(1, lecturesCount)

        let trimmedBuilding = building?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.building = (trimmedBuilding?.isEmpty == false) ? trimmedBuilding : nil
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case subjectID
        case day
        case startTime
        case endTime
        case lecture
        case building
        case lecturesCount
        case location
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        let subjectID = try container.decode(UUID.self, forKey: .subjectID)
        let day = try container.decode(Weekday.self, forKey: .day)
        let startTime = try container.decode(Date.self, forKey: .startTime)
        let endTime = try container.decode(Date.self, forKey: .endTime)

        // Backward compatibility for older data using `location`
        let lecture = try container.decodeIfPresent(String.self, forKey: .lecture)
            ?? container.decodeIfPresent(String.self, forKey: .location)
            ?? ""
        let building = try container.decodeIfPresent(String.self, forKey: .building)
        let lecturesCount = try container.decodeIfPresent(Int.self, forKey: .lecturesCount) ?? 1

        self.init(
            id: id,
            subjectID: subjectID,
            day: day,
            startTime: startTime,
            endTime: endTime,
            lecture: lecture,
            building: building,
            lecturesCount: lecturesCount
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(subjectID, forKey: .subjectID)
        try container.encode(day, forKey: .day)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(lecture, forKey: .lecture)
        try container.encodeIfPresent(building, forKey: .building)
        try container.encode(lecturesCount, forKey: .lecturesCount)
    }
}
