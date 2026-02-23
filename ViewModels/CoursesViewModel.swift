//
//  File.swift
//  AttendiFy
//
//  Created by Akshit Goyal on 20/02/26.
//

import Foundation
import SwiftUI

class CoursesViewModel: ObservableObject {

    @Published var subjects: [Subject] = []

    init() {
        subjects = []
    }

    func addSubject(_ subject: Subject) {
        subjects.append(subject)
    }

    func delete(at offsets: IndexSet) {
        subjects.remove(atOffsets: offsets)
    }

    var overallAttendance: Double {
        let total = subjects.reduce(0) { $0 + $1.totalClasses }
        let attended = subjects.reduce(0) { $0 + $1.presentCount }

        guard total > 0 else { return 0 }
        return Double(attended) / Double(total)
    }

    var riskSubjects: [Subject] {
        subjects.filter { $0.attendanceRisk == .critical }
    }
}
