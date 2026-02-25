import Foundation

// MARK: - Grade Point System

enum GradeLetter: String, Codable, CaseIterable, Identifiable {
    case aPlus = "A+"
    case a = "A"
    case bPlus = "B+"
    case b = "B"
    case cPlus = "C+"
    case c = "C"
    case d = "D"
    case f = "F"

    var id: String { rawValue }

    var points: Double {
        switch self {
        case .aPlus: return 10.0
        case .a: return 9.0
        case .bPlus: return 8.0
        case .b: return 7.0
        case .cPlus: return 6.0
        case .c: return 5.0
        case .d: return 4.0
        case .f: return 0.0
        }
    }

    var requiredPercentage: Double {
        switch self {
        case .aPlus: return 90.0
        case .a: return 80.0
        case .bPlus: return 70.0
        case .b: return 60.0
        case .cPlus: return 50.0
        case .c: return 45.0
        case .d: return 40.0
        case .f: return 0.0
        }
    }

    static func fromPercentage(_ value: Double) -> GradeLetter {
        switch value {
        case 90...: return .aPlus
        case 80..<90: return .a
        case 70..<80: return .bPlus
        case 60..<70: return .b
        case 50..<60: return .cPlus
        case 45..<50: return .c
        case 40..<45: return .d
        default: return .f
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

struct AttendanceRecord: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var status: AttendanceStatus
}

// MARK: - Assessment Component

struct AssessmentComponent: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var weightage: Double // 0...100
    var maxMarks: Double
    var earnedMarks: Double?
    var isBestOf: Bool = false
}

// MARK: - Semester CGPA Entry

struct SemesterCGPAEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var semester: Int
    var sgpa: Double
    var credits: Int
}

// MARK: - Attendance Risk

enum AttendanceRisk: String, Codable {
    case safe
    case warning
    case critical
}

enum DepartmentRuleSet: String, Codable, CaseIterable {
    case standard
    case engineering
    case medical
    case management
}

struct SubjectAcademicProfile: Codable, Equatable {
    var departmentRuleSet: DepartmentRuleSet
    var choTargetMarks: Double?
    var gradingRuleID: String?

    init(
        departmentRuleSet: DepartmentRuleSet = .standard,
        choTargetMarks: Double? = nil,
        gradingRuleID: String? = nil
    ) {
        self.departmentRuleSet = departmentRuleSet
        self.choTargetMarks = choTargetMarks
        self.gradingRuleID = gradingRuleID
    }
}

// MARK: - Subject

struct Subject: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var shortName: String
    var credits: Double
    var includeInGPA: Bool
    var minimumRequired: Double

    // Attendance
    var attendanceRecords: [AttendanceRecord]
    var manualPresent: Int
    var manualTotal: Int

    // Assessment
    var assessmentComponents: [AssessmentComponent]
    var targetGrade: GradeLetter
    var predictedGrade: GradeLetter?

    // Scalability
    var academicProfile: SubjectAcademicProfile

    // CHO + CGPA extension fields
    var internalMarksObtained: Double
    var internalMaxMarks: Double
    var endSemMaxMarks: Double
    var choPassingMarks: Double

    init(
        id: UUID = UUID(),
        name: String,
        shortName: String,
        credits: Double,
        includeInGPA: Bool = true,
        minimumRequired: Double = 75.0,
        attendanceRecords: [AttendanceRecord] = [],
        manualPresent: Int = 0,
        manualTotal: Int = 0,
        assessmentComponents: [AssessmentComponent] = [],
        targetGrade: GradeLetter = .a,
        predictedGrade: GradeLetter? = nil,
        academicProfile: SubjectAcademicProfile = SubjectAcademicProfile(),
        internalMarksObtained: Double = 0,
        internalMaxMarks: Double = 40,
        endSemMaxMarks: Double = 60,
        choPassingMarks: Double = 40
    ) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.credits = max(0, credits)
        self.includeInGPA = includeInGPA
        self.minimumRequired = min(100.0, max(50.0, minimumRequired))
        self.attendanceRecords = attendanceRecords
        self.manualTotal = max(0, manualTotal)
        self.manualPresent = max(0, min(manualPresent, max(0, manualTotal)))
        self.assessmentComponents = assessmentComponents
        self.targetGrade = targetGrade
        self.predictedGrade = predictedGrade
        self.academicProfile = academicProfile
        self.internalMaxMarks = max(0, internalMaxMarks)
        self.endSemMaxMarks = max(0, endSemMaxMarks)
        self.choPassingMarks = max(0, choPassingMarks)
        self.internalMarksObtained = min(max(0, internalMarksObtained), self.internalMaxMarks)
    }

    private var minimumRequiredRatio: Double {
        min(1.0, max(0.0, minimumRequired / 100.0))
    }

    private var presentFromRecords: Int {
        attendanceRecords.filter { $0.status == .present }.count
    }

    var presentCount: Int {
        presentFromRecords + manualPresent
    }

    var totalClasses: Int {
        let fromRecords = attendanceRecords.filter { $0.status != .cancelled }.count
        return fromRecords + manualTotal
    }

    var attendancePercentage: Double {
        guard totalClasses > 0 else { return 100.0 }
        return (Double(presentCount) / Double(totalClasses)) * 100.0
    }

    var attendanceRatio: Double {
        attendancePercentage / 100.0
    }

    var attendanceRisk: AttendanceRisk {
        if attendancePercentage >= minimumRequired {
            return .safe
        }
        if attendancePercentage >= (minimumRequired - 10.0) {
            return .warning
        }
        return .critical
    }

    // x <= (A / M) - T
    var classesCanMiss: Int {
        let a = Double(presentCount)
        let t = Double(totalClasses)
        let m = minimumRequiredRatio
        guard m > 0 else { return 0 }
        let value = floor((a / m) - t)
        return max(0, Int(value.isFinite ? value : 0))
    }

    // x >= (M * T - A) / (1 - M)
    var classesToRecover: Int {
        let a = Double(presentCount)
        let t = Double(totalClasses)
        let m = minimumRequiredRatio

        if m >= 1.0 {
            return attendancePercentage >= 100.0 ? 0 : Int.max
        }

        let value = ceil(((m * t) - a) / (1.0 - m))
        return max(0, Int(value.isFinite ? value : 0))
    }

    var isRecoveryPossible: Bool {
        classesToRecover != Int.max
    }

    var attendanceGuidance: String {
        if classesToRecover > 0 {
            return isRecoveryPossible
                ? "Attend next \(classesToRecover) classes"
                : "Recovery not possible at this threshold"
        }
        return "You can miss \(classesCanMiss) classes"
    }

    var requiredEndSemRaw: Double {
        choPassingMarks - internalMarksObtained
    }

    var requiredEndSemMarks: Double {
        min(endSemMaxMarks, max(0, requiredEndSemRaw))
    }

    var isCHORisk: Bool {
        requiredEndSemRaw > endSemMaxMarks
    }

    var currentOverallPercentage: Double {
        let totalMax = internalMaxMarks + endSemMaxMarks
        guard totalMax > 0 else { return 0 }
        return (internalMarksObtained / totalMax) * 100.0
    }

    func projectedOverallPercentage(simulatedEndSem: Double) -> Double {
        let totalMax = internalMaxMarks + endSemMaxMarks
        guard totalMax > 0 else { return 0 }
        let safeSimulated = min(max(0, simulatedEndSem), endSemMaxMarks)
        return ((internalMarksObtained + safeSimulated) / totalMax) * 100.0
    }

    var scoredPercentage: Double? {
        let scoredPairs = assessmentComponents.compactMap { component -> (Double, Double)? in
            guard let earned = component.earnedMarks, component.maxMarks > 0 else { return nil }
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

    // ((A + x) / (T + x)) * 100
    func projectedAttendance(afterAttending additionalClasses: Int) -> Double {
        let safeAdditional = max(0, additionalClasses)
        let attended = Double(presentCount + safeAdditional)
        let total = Double(totalClasses + safeAdditional)
        guard total > 0 else { return 100 }
        return (attended / total) * 100
    }

    // x >= (P*T - A) / (1 - P), where A=current scored ratio, T=1.0
    var targetPlannerUnitsNeeded: Double {
        let p = min(0.999, max(0, targetGrade.requiredPercentage / 100.0))
        let a = min(1, max(0, (weightedScoredPercentage ?? 0) / 100.0))
        let t = 1.0
        guard p < 1 else { return .infinity }
        let value = (p * t - a) / (1 - p)
        return max(0, value)
    }

    var weightedScoredPercentage: Double? {
        guard !assessmentComponents.isEmpty else { return nil }

        let bestOfGroups = Dictionary(grouping: assessmentComponents.filter { $0.isBestOf }, by: \.name)
            .compactMapValues { group -> AssessmentComponent? in
                group.max { lhs, rhs in
                    (lhs.earnedMarks ?? 0) < (rhs.earnedMarks ?? 0)
                }
            }

        var effective: [AssessmentComponent] = assessmentComponents.filter { !$0.isBestOf }
        effective.append(contentsOf: bestOfGroups.values)

        let weightedPairs = effective.compactMap { component -> (Double, Double)? in
            guard let earned = component.earnedMarks, component.maxMarks > 0 else { return nil }
            let normalized = earned / component.maxMarks
            return (normalized * component.weightage, component.weightage)
        }
        guard !weightedPairs.isEmpty else { return nil }
        let weightedScored = weightedPairs.reduce(0) { $0 + $1.0 }
        let weightedTotal = weightedPairs.reduce(0) { $0 + $1.1 }
        guard weightedTotal > 0 else { return nil }
        return (weightedScored / weightedTotal) * 100
    }

    var isTargetGradeImpossible: Bool {
        guard let current = weightedScoredPercentage else { return false }
        let required = targetGrade.requiredPercentage
        let remainingWeight = max(0, 100 - assessmentComponents.reduce(0) { $0 + $1.weightage })
        let maxPossible = current + remainingWeight
        return maxPossible < required
    }

    mutating func markAttendance(isPresent: Bool) {
        manualTotal += 1
        if isPresent {
            manualPresent = min(manualTotal, manualPresent + 1)
        }
    }

    mutating func updateManualAttendance(present: Int, total: Int) {
        manualTotal = max(0, total)
        manualPresent = max(0, min(present, manualTotal))
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case shortName
        case credits
        case includeInGPA
        case minimumRequired
        case attendanceRecords
        case manualPresent
        case manualTotal
        case assessmentComponents
        case targetGrade
        case predictedGrade
        case academicProfile
        case internalMarksObtained
        case internalMaxMarks
        case endSemMaxMarks
        case choPassingMarks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        let name = try container.decode(String.self, forKey: .name)
        let shortName = try container.decodeIfPresent(String.self, forKey: .shortName) ?? name
        let credits = try container.decodeIfPresent(Double.self, forKey: .credits)
            ?? Double(try container.decodeIfPresent(Int.self, forKey: .credits) ?? 0)
        let includeInGPA = try container.decodeIfPresent(Bool.self, forKey: .includeInGPA) ?? true
        let minimumRequired = try container.decodeIfPresent(Double.self, forKey: .minimumRequired) ?? 75.0
        let attendanceRecords = try container.decodeIfPresent([AttendanceRecord].self, forKey: .attendanceRecords) ?? []
        let manualPresent = try container.decodeIfPresent(Int.self, forKey: .manualPresent) ?? 0
        let manualTotal = try container.decodeIfPresent(Int.self, forKey: .manualTotal) ?? 0
        let assessmentComponents = try container.decodeIfPresent([AssessmentComponent].self, forKey: .assessmentComponents) ?? []
        let targetGrade = try container.decodeIfPresent(GradeLetter.self, forKey: .targetGrade) ?? .a
        let predictedGrade = try container.decodeIfPresent(GradeLetter.self, forKey: .predictedGrade)
        let academicProfile = try container.decodeIfPresent(SubjectAcademicProfile.self, forKey: .academicProfile) ?? SubjectAcademicProfile()
        let internalMarksObtained = try container.decodeIfPresent(Double.self, forKey: .internalMarksObtained) ?? 0
        let internalMaxMarks = try container.decodeIfPresent(Double.self, forKey: .internalMaxMarks) ?? 40
        let endSemMaxMarks = try container.decodeIfPresent(Double.self, forKey: .endSemMaxMarks) ?? 60
        let choPassingMarks = try container.decodeIfPresent(Double.self, forKey: .choPassingMarks) ?? 40

        self.init(
            id: id,
            name: name,
            shortName: shortName,
            credits: credits,
            includeInGPA: includeInGPA,
            minimumRequired: minimumRequired,
            attendanceRecords: attendanceRecords,
            manualPresent: manualPresent,
            manualTotal: manualTotal,
            assessmentComponents: assessmentComponents,
            targetGrade: targetGrade,
            predictedGrade: predictedGrade,
            academicProfile: academicProfile,
            internalMarksObtained: internalMarksObtained,
            internalMaxMarks: internalMaxMarks,
            endSemMaxMarks: endSemMaxMarks,
            choPassingMarks: choPassingMarks
        )
    }
}

// MARK: - Dashboard Adapter

struct SubjectAttendance: Identifiable, Equatable {
    let id: UUID
    let subject: String
    let shortName: String
    let attended: Int
    let total: Int

    var percentage: Double {
        total == 0 ? 100.0 : (Double(attended) / Double(total)) * 100.0
    }

    static func from(_ subject: Subject) -> SubjectAttendance {
        SubjectAttendance(
            id: subject.id,
            subject: subject.name,
            shortName: subject.shortName,
            attended: subject.presentCount,
            total: subject.totalClasses
        )
    }
}
