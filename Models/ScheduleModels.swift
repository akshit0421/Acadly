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

    var id: String { rawValue }
}

struct ScheduleItem: Identifiable, Codable {

    var id: UUID = UUID()
    var subjectID: UUID
    var day: Weekday
    var startTime: Date
    var endTime: Date
    var location: String
}
