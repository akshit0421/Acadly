import Foundation

// MARK: - Grade Point System

enum GradeLetter: String, Codable, CaseIterable, Identifiable {
    case aPlus = "A+"
    case a     = "A"
    case bPlus = "B+"
    case b     = "B"
    case cPlus = "C+"
    case c     = "C"
    case d     = "D"
    case f     = "F"

    var id: String { rawValue }

    var points: Double {
        switch self {
        case .aPlus: return 10.0
        case .a:     return 9.0
        case .bPlus: return 8.0
        case .b:     return 7.0
        case .cPlus: return 6.0
        case .c:     return 5.0
        case .d:     return 4.0
        case .f:     return 0.0
        }
    }

    var requiredPercentage: Double {
        switch self {
        case .aPlus: return 90.0
        case .a:     return 80.0
        case .bPlus: return 70.0
        case .b:     return 60.0
        case .cPlus: return 50.0
        case .c:     return 45.0
        case .d:     return 40.0
        case .f:     return 0.0
        }
    }
}

// MARK: - Attendance Status

enum AttendanceStatus: String, Codable {
    case present
    case absent
    case cancelled
}

// MARK: - Attendance Record

struct AttendanceRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var status: AttendanceStatus
}

// MARK: - Assessment Component

struct AssessmentComponent: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var weightage: Double      // 0–100
    var maxMarks: Double
    var earnedMarks: Double?   // nil = not yet entered
    var isBestOf: Bool = false
}

// MARK: - Semester CGPA Entry

struct SemesterCGPAEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var semester: Int
    var sgpa: Double
    var credits: Int
}

// MARK: - Attendance Risk (Logic Only)

enum AttendanceRisk: String, Codable {
    case safe
    case warning
    case critical
}

// MARK: - Subject (Core Academic Domain Model)

struct Subject: Identifiable, Codable {

    var id: UUID = UUID()
    var name: String
    var shortName: String
    var credits: Int
    var includeInGPA: Bool = true

    // Attendance
    var attendanceRecords: [AttendanceRecord] = []
    var manualPresent: Int = 0
    var manualTotal: Int = 0

    // Assessment
    var assessmentComponents: [AssessmentComponent] = []
    var targetGrade: GradeLetter = .a
    var predictedGrade: GradeLetter? = nil

    // MARK: - Attendance Computation

    var presentCount: Int {
        let fromRecords = attendanceRecords
            .filter { $0.status == .present }
            .count
        return fromRecords + manualPresent
    }

    var totalClasses: Int {
        let fromRecords = attendanceRecords
            .filter { $0.status != .cancelled }
            .count
        return fromRecords + manualTotal
    }

    var attendancePercentage: Double {
        guard totalClasses > 0 else { return 0 }
        return Double(presentCount) / Double(totalClasses)
    }

    var attendanceRisk: AttendanceRisk {
        switch attendancePercentage {
        case 0.75...:
            return .safe
        case 0.60..<0.75:
            return .warning
        default:
            return .critical
        }
    }

    // MARK: - Assessment Computation

    var scoredPercentage: Double? {

        let scoredPairs = assessmentComponents.compactMap { component -> (Double, Double)? in
            guard let earned = component.earnedMarks else { return nil }
            return (earned, component.maxMarks)
        }

        guard !scoredPairs.isEmpty else { return nil }

        let totalMax = scoredPairs.reduce(0) { $0 + $1.1 }
        let totalEarned = scoredPairs.reduce(0) { $0 + $1.0 }

        guard totalMax > 0 else { return nil }

        return (totalEarned / totalMax) * 100.0
    }

    var inferredGrade: GradeLetter {
        guard let pct = scoredPercentage else {
            return predictedGrade ?? .b
        }

        for grade in GradeLetter.allCases {
            if pct >= grade.requiredPercentage {
                return grade
            }
        }

        return .f
    }
}

// MARK: - Dashboard Adapter (No UI Types)

struct SubjectAttendance: Identifiable {

    let id = UUID()
    let subject: String
    let shortName: String
    let attended: Int
    let total: Int

    var percentage: Double {
        total == 0 ? 0 : Double(attended) / Double(total)
    }

    static func from(_ subject: Subject) -> SubjectAttendance {
        SubjectAttendance(
            subject: subject.name,
            shortName: subject.shortName,
            attended: subject.presentCount,
            total: subject.totalClasses
        )
    }
}
